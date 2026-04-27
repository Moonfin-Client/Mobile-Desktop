import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';

import '../../../util/focus/dpad_keys.dart';
import '../overlay_sheet.dart';
import 'preference_binding.dart';

Widget _withBackClose(BuildContext dialogContext, Widget child) {
  var closed = false;
  void closeDialog() {
    if (closed) return;
    closed = true;
    Navigator.pop(dialogContext);
  }

  return Shortcuts(
    shortcuts: const <ShortcutActivator, Intent>{
      SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      SingleActivator(LogicalKeyboardKey.goBack): DismissIntent(),
      SingleActivator(LogicalKeyboardKey.browserBack): DismissIntent(),
      SingleActivator(LogicalKeyboardKey.gameButtonB): DismissIntent(),
    },
    child: Actions(
      actions: <Type, Action<Intent>>{
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            closeDialog();
            return null;
          },
        ),
      },
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, event) {
          if (!event.logicalKey.isBackKey) return KeyEventResult.ignored;
          if (closed) return KeyEventResult.handled;
          if (event is KeyDownEvent || event is KeyUpEvent) {
            closeDialog();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: FocusScope(
          autofocus: true,
          child: child,
        ),
      ),
    ),
  );
}

const TextStyle _kSettingsTitleTextStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
);
const TextStyle _kSettingsSubtitleTextStyle = TextStyle(fontSize: 12);
const TextStyle _kSettingsDescriptionTextStyle = TextStyle(fontSize: 11);

Widget _buildSubtitle(String value, String? description) {
  if (description == null) {
    return Text(value, style: _kSettingsSubtitleTextStyle);
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: _kSettingsSubtitleTextStyle),
      const SizedBox(height: 2),
      Text(description, style: _kSettingsDescriptionTextStyle),
    ],
  );
}

void _ensureFocusVisible(BuildContext context, {double alignment = 0.9}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    Scrollable.ensureVisible(
      context,
      alignment: alignment,
      alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
    );
  });
}

class SettingsListTypography extends StatelessWidget {
  final Widget child;

  const SettingsListTypography({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTileTheme(
      data: ListTileTheme.of(context).copyWith(
        titleTextStyle:
            theme.textTheme.bodyMedium?.merge(_kSettingsTitleTextStyle) ??
            _kSettingsTitleTextStyle,
        subtitleTextStyle:
            theme.textTheme.bodySmall?.merge(_kSettingsSubtitleTextStyle) ??
            _kSettingsSubtitleTextStyle,
      ),
      child: child,
    );
  }
}

class SwitchPreferenceTile extends StatefulWidget {
  final Preference<bool> preference;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget Function(double size, Color color)? iconBuilder;
  final VoidCallback? onChanged;

  const SwitchPreferenceTile({
    super.key,
    required this.preference,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconBuilder,
    this.onChanged,
  });

  @override
  State<SwitchPreferenceTile> createState() => _SwitchPreferenceTileState();
}

class _SwitchPreferenceTileState extends State<SwitchPreferenceTile> {
  late final PreferenceBinding<bool> _binding;

  @override
  void initState() {
    super.initState();
    _binding = PreferenceBinding(GetIt.instance<PreferenceStore>(), widget.preference);
  }

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TvFocusHighlight(
      builder: (context, focused) => ValueListenableBuilder<bool>(
        valueListenable: _binding,
        builder: (context, value, _) => SwitchListTile(
          secondary: widget.iconBuilder != null
              ? widget.iconBuilder!(24, focused ? Colors.black54 : (Theme.of(context).iconTheme.color ?? Colors.white))
              : widget.icon != null
                  ? Icon(widget.icon)
                  : null,
            title: Text(widget.title, style: _kSettingsTitleTextStyle),
            subtitle: widget.subtitle != null
              ? Text(widget.subtitle!, style: _kSettingsSubtitleTextStyle)
              : null,
          value: value,
          onChanged: (v) {
            _binding.value = v;
            widget.onChanged?.call();
          },
        ),
      ),
    );
  }
}

class EnumPreferenceTile<T extends Enum> extends StatefulWidget {
  final EnumPreference<T> preference;
  final String title;
  final String? description;
  final IconData? icon;
  final String Function(T value) labelOf;
  final VoidCallback? onChanged;

  const EnumPreferenceTile({
    super.key,
    required this.preference,
    required this.title,
    required this.labelOf,
    this.description,
    this.icon,
    this.onChanged,
  });

  @override
  State<EnumPreferenceTile<T>> createState() => _EnumPreferenceTileState<T>();
}

class _EnumPreferenceTileState<T extends Enum> extends State<EnumPreferenceTile<T>> {
  late final PreferenceBinding<T> _binding;
  bool _pickerOpen = false;

  @override
  void initState() {
    super.initState();
    _binding = PreferenceBinding(GetIt.instance<PreferenceStore>(), widget.preference);
  }

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TvFocusHighlight(
      builder: (context, _) => ValueListenableBuilder<T>(
        valueListenable: _binding,
        builder: (context, value, _) => ListTile(
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          leading: widget.icon != null ? Icon(widget.icon) : null,
          title: Text(widget.title, style: _kSettingsTitleTextStyle),
          subtitle: _buildSubtitle(widget.labelOf(value), widget.description),
          isThreeLine: widget.description != null,
          onTap: () => _showPicker(context, value),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, T current) async {
    if (_pickerOpen) return;
    _pickerOpen = true;
    final values = widget.preference.values.toList();
    final selectedIndex = values.indexOf(current);
    final autofocusIndex = selectedIndex >= 0 ? selectedIndex : 0;
    var picked = false;
    final result = await showFocusRestoringDialog<T>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => _withBackClose(
        ctx,
        SimpleDialog(
          title: Text(widget.title, style: _kSettingsTitleTextStyle),
          children: values.asMap().entries.map((entry) {
            final i = entry.key;
            final v = entry.value;
            final selected = v == current;
            return TvFocusHighlight(
              builder: (_, _) => ListTile(
                autofocus: i == autofocusIndex,
                title: Text(widget.labelOf(v), style: _kSettingsTitleTextStyle),
                trailing: selected ? const Icon(Icons.check) : null,
                onTap: () {
                  if (picked) return;
                  picked = true;
                  Navigator.pop(ctx, v);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
    _pickerOpen = false;
    if (!mounted || result == null || result == _binding.value) return;
    _binding.value = result;
    widget.onChanged?.call();
  }
}

class SliderPreferenceTile extends StatefulWidget {
  final Preference<int> preference;
  final String title;
  final IconData? icon;
  final double min;
  final double max;
  final int? divisions;
  final String Function(int value)? labelOf;
  final VoidCallback? onChangeEnd;

  const SliderPreferenceTile({
    super.key,
    required this.preference,
    required this.title,
    this.icon,
    required this.min,
    required this.max,
    this.divisions,
    this.labelOf,
    this.onChangeEnd,
  });

  @override
  State<SliderPreferenceTile> createState() => _SliderPreferenceTileState();
}

class _SliderPreferenceTileState extends State<SliderPreferenceTile> {
  late final PreferenceBinding<int> _binding;
  late final FocusNode _outerFocusNode;
  late final FocusNode _sliderInternalNode;
  bool _outerFocused = false;

  int get _step {
    if (widget.divisions != null && widget.divisions! > 0) {
      final s = ((widget.max - widget.min) / widget.divisions!).round();
      return s < 1 ? 1 : s;
    }
    return 1;
  }

  @override
  void initState() {
    super.initState();
    _binding = PreferenceBinding(GetIt.instance<PreferenceStore>(), widget.preference);
    _outerFocusNode = FocusNode(debugLabel: 'SliderPrefTileOuter');
    _sliderInternalNode = FocusNode(
      debugLabel: 'SliderPrefTileInner',
      canRequestFocus: false,
      skipTraversal: true,
    );
  }

  @override
  void dispose() {
    _outerFocusNode.dispose();
    _sliderInternalNode.dispose();
    _binding.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      node.previousFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      node.nextFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      final delta = key == LogicalKeyboardKey.arrowLeft ? -_step : _step;
      final current = _binding.value;
      final next = (current + delta)
          .clamp(widget.min.round(), widget.max.round());
      if (next != current) {
        _binding.value = next;
        widget.onChangeEnd?.call();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Focus(
      focusNode: _outerFocusNode,
      onKeyEvent: _onKeyEvent,
      onFocusChange: (focused) {
        if (focused) {
          _ensureFocusVisible(context);
        }
        if (_outerFocused != focused && mounted) {
          setState(() => _outerFocused = focused);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _outerFocused ? Colors.white : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTileTheme.merge(
          textColor: _outerFocused ? Colors.black87 : Colors.white,
          iconColor: _outerFocused ? Colors.black54 : Colors.white70,
          titleTextStyle: _kSettingsTitleTextStyle,
          subtitleTextStyle: _kSettingsSubtitleTextStyle,
          child: ValueListenableBuilder<int>(
            valueListenable: _binding,
            builder: (context, value, _) => ListTile(
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                leading: widget.icon != null ? Icon(widget.icon) : null,
                title: Text(widget.title, style: _kSettingsTitleTextStyle),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.labelOf != null)
                      Text(
                        widget.labelOf!(value),
                        style: TextStyle(
                          fontSize: _kSettingsSubtitleTextStyle.fontSize,
                          color: _outerFocused ? Colors.black54 : Colors.white70,
                        ),
                      ),
                    Slider(
                      focusNode: _sliderInternalNode,
                      value: value.toDouble().clamp(widget.min, widget.max),
                      min: widget.min,
                      max: widget.max,
                      divisions: widget.divisions,
                      label: widget.labelOf?.call(value) ?? value.toString(),
                      onChanged: (v) => _binding.value = v.round(),
                      onChangeEnd: (_) => widget.onChangeEnd?.call(),
                    ),
                  ],
                ),
              ),
          ),
        ),
      ),
    );
  }
}

class StringPickerPreferenceTile extends StatefulWidget {
  final Preference<String> preference;
  final String title;
  final String? description;
  final IconData? icon;
  final Map<String, String> options;
  final VoidCallback? onChanged;

  const StringPickerPreferenceTile({
    super.key,
    required this.preference,
    required this.title,
    this.description,
    this.icon,
    required this.options,
    this.onChanged,
  });

  @override
  State<StringPickerPreferenceTile> createState() => _StringPickerPreferenceTileState();
}

class _StringPickerPreferenceTileState extends State<StringPickerPreferenceTile> {
  late final PreferenceBinding<String> _binding;
  bool _pickerOpen = false;

  @override
  void initState() {
    super.initState();
    _binding = PreferenceBinding(GetIt.instance<PreferenceStore>(), widget.preference);
  }

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TvFocusHighlight(
      builder: (context, _) => ValueListenableBuilder<String>(
        valueListenable: _binding,
        builder: (context, value, _) => ListTile(
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          leading: widget.icon != null ? Icon(widget.icon) : null,
          title: Text(widget.title, style: _kSettingsTitleTextStyle),
          subtitle: _buildSubtitle(
            widget.options[value] ?? value,
            widget.description,
          ),
          isThreeLine: widget.description != null,
          onTap: () => _showPicker(context, value),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, String current) async {
    if (_pickerOpen) return;
    _pickerOpen = true;
    final entries = widget.options.entries.toList();
    final selectedIndex = entries.indexWhere((e) => e.key == current);
    final autofocusIndex = selectedIndex >= 0 ? selectedIndex : 0;
    var picked = false;
    final result = await showFocusRestoringDialog<String>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => _withBackClose(
        ctx,
        SimpleDialog(
          title: Text(widget.title, style: _kSettingsTitleTextStyle),
          children: entries.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final selected = e.key == current;
            return TvFocusHighlight(
              builder: (_, _) => ListTile(
                autofocus: i == autofocusIndex,
                title: Text(e.value, style: _kSettingsTitleTextStyle),
                trailing: selected ? const Icon(Icons.check) : null,
                onTap: () {
                  if (picked) return;
                  picked = true;
                  Navigator.pop(ctx, e.key);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
    _pickerOpen = false;
    if (!mounted || result == null) return;
    if (result != _binding.value) {
      _binding.value = result;
      widget.onChanged?.call();
    }
  }
}

class IntPickerPreferenceTile extends StatefulWidget {
  final Preference<int> preference;
  final String title;
  final String? description;
  final IconData? icon;
  final Map<int, String> options;
  final VoidCallback? onChanged;

  const IntPickerPreferenceTile({
    super.key,
    required this.preference,
    required this.title,
    required this.options,
    this.description,
    this.icon,
    this.onChanged,
  });

  @override
  State<IntPickerPreferenceTile> createState() =>
      _IntPickerPreferenceTileState();
}

class _IntPickerPreferenceTileState extends State<IntPickerPreferenceTile> {
  late final PreferenceBinding<int> _binding;
  bool _pickerOpen = false;

  @override
  void initState() {
    super.initState();
    _binding = PreferenceBinding(
      GetIt.instance<PreferenceStore>(),
      widget.preference,
    );
  }

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TvFocusHighlight(
      builder: (context, _) => ValueListenableBuilder<int>(
        valueListenable: _binding,
        builder: (context, value, _) => ListTile(
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          leading: widget.icon != null ? Icon(widget.icon) : null,
          title: Text(widget.title, style: _kSettingsTitleTextStyle),
          subtitle: _buildSubtitle(
            widget.options[value] ?? value.toString(),
            widget.description,
          ),
          isThreeLine: widget.description != null,
          onTap: () => _showPicker(context, value),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, int current) async {
    if (_pickerOpen) return;
    _pickerOpen = true;
    final entries = widget.options.entries.toList();
    final selectedIndex = entries.indexWhere((e) => e.key == current);
    final autofocusIndex = selectedIndex >= 0 ? selectedIndex : 0;
    var picked = false;
    final result = await showFocusRestoringDialog<int>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => _withBackClose(
        ctx,
        SimpleDialog(
          title: Text(widget.title, style: _kSettingsTitleTextStyle),
          children: entries.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final selected = e.key == current;
            return TvFocusHighlight(
              builder: (_, _) => ListTile(
                autofocus: i == autofocusIndex,
                title: Text(e.value, style: _kSettingsTitleTextStyle),
                trailing: selected ? const Icon(Icons.check) : null,
                onTap: () {
                  if (picked) return;
                  picked = true;
                  Navigator.pop(ctx, e.key);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
    _pickerOpen = false;
    if (!mounted || result == null) return;
    if (result != _binding.value) {
      _binding.value = result;
      widget.onChanged?.call();
    }
  }
}

class TvFocusHighlight extends StatefulWidget {
  final Widget Function(BuildContext context, bool focused) builder;

  const TvFocusHighlight({super.key, required this.builder});

  @override
  State<TvFocusHighlight> createState() => _TvFocusHighlightState();
}

class _TvFocusHighlightState extends State<TvFocusHighlight> {
  bool _focused = false;

  void _onFocusChange(bool focused) {
    if (focused) {
      _ensureFocusVisible(context);
    }
    if (_focused != focused && mounted) {
      setState(() => _focused = focused);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Focus(
      canRequestFocus: true,
      skipTraversal: true,
      descendantsAreFocusable: true,
      onFocusChange: _onFocusChange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _focused ? Colors.white : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTileTheme.merge(
          textColor: _focused ? Colors.black87 : Colors.white,
          iconColor: _focused ? Colors.black54 : Colors.white70,
          titleTextStyle: _kSettingsTitleTextStyle,
          subtitleTextStyle: _kSettingsSubtitleTextStyle,
          child: Builder(builder: (ctx) => widget.builder(ctx, _focused)),
        ),
      ),
    );
  }
}
