import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_design/jellyfin_design.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';

import '../../../preference/user_preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../../../util/platform_detection.dart';
import '../../widgets/overlay_sheet.dart';
import '../../widgets/settings/preference_binding.dart';
import '../../widgets/settings/preference_tiles.dart';
import '../../widgets/subtitle_preview.dart';
import 'settings_app_bar.dart';
import '../../widgets/focus/request_initial_focus.dart';

class SubtitleCustomizationScreen extends StatefulWidget {
  const SubtitleCustomizationScreen({super.key});

  @override
  State<SubtitleCustomizationScreen> createState() =>
      _SubtitleCustomizationScreenState();
}

class _SubtitleCustomizationScreenState
    extends State<SubtitleCustomizationScreen> {
  late final PreferenceBinding<double> _sizeBind;
  late final PreferenceBinding<double> _offsetBind;
  late final FocusNode _sizeOuterNode;
  late final FocusNode _sizeInnerNode;
  late final FocusNode _offsetOuterNode;
  late final FocusNode _offsetInnerNode;
  bool _sizeFocused = false;
  bool _offsetFocused = false;

  @override
  void initState() {
    super.initState();
    final store = GetIt.instance<PreferenceStore>();
    _sizeBind = PreferenceBinding(store, UserPreferences.subtitlesTextSize);
    _offsetBind =
        PreferenceBinding(store, UserPreferences.subtitlesOffsetPosition);
    _sizeOuterNode = FocusNode(debugLabel: 'SubtitleSizeOuter');
    _sizeInnerNode = FocusNode(
      debugLabel: 'SubtitleSizeInner',
      canRequestFocus: false,
      skipTraversal: true,
    );
    _offsetOuterNode = FocusNode(debugLabel: 'SubtitleOffsetOuter');
    _offsetInnerNode = FocusNode(
      debugLabel: 'SubtitleOffsetInner',
      canRequestFocus: false,
      skipTraversal: true,
    );
  }

  KeyEventResult _sliderKeyHandler({
    required FocusNode node,
    required KeyEvent event,
    required PreferenceBinding<double> binding,
    required double min,
    required double max,
    required double step,
  }) {
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
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      final delta = key == LogicalKeyboardKey.arrowLeft ? -step : step;
      final next = (binding.value + delta).clamp(min, max);
      if (next != binding.value) binding.value = next;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _sizeOuterNode.dispose();
    _sizeInnerNode.dispose();
    _offsetOuterNode.dispose();
    _offsetInnerNode.dispose();
    _sizeBind.dispose();
    _offsetBind.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RequestInitialFocus(child: _buildContent(context));

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: buildSettingsAppBar(context, Text(l10n.subtitleCustomization)),
      body: ListView(
        children: [
          const SubtitlePreview(),
          _ColorPickerTile(
            title: l10n.textFillColor,
            icon: Icons.format_color_text,
            preference: UserPreferences.subtitlesTextColor,
            allowTransparent: false,
          ),
          _ColorPickerTile(
            title: l10n.textStrokeColor,
            icon: Icons.border_color,
            preference: UserPreferences.subtitleTextStrokeColor,
          ),
          _ColorPickerTile(
            title: l10n.backgroundColor,
            icon: Icons.format_color_fill,
            preference: UserPreferences.subtitlesBackgroundColor,
          ),
          _sliderTile(
            context: context,
            icon: Icons.format_size,
            label: l10n.subtitleSize,
            binding: _sizeBind,
            outerNode: _sizeOuterNode,
            innerNode: _sizeInnerNode,
            focused: _sizeFocused,
            onFocusChange: (f) {
              if (_sizeFocused != f && mounted) {
                setState(() => _sizeFocused = f);
              }
            },
            min: 12,
            max: 48,
            divisions: 18,
            step: 2,
            labelBuilder: (v) => l10n.pixelValue(v.round()),
          ),
          _sliderTile(
            context: context,
            icon: Icons.vertical_align_bottom,
            label: l10n.verticalOffset,
            binding: _offsetBind,
            outerNode: _offsetOuterNode,
            innerNode: _offsetInnerNode,
            focused: _offsetFocused,
            onFocusChange: (f) {
              if (_offsetFocused != f && mounted) {
                setState(() => _offsetFocused = f);
              }
            },
            min: 0.0,
            max: 0.5,
            divisions: 50,
            step: 0.01,
            labelBuilder: (v) => l10n.percentValue((v * 100).round()),
          ),
        ],
      ),
    );
  }

  Widget _sliderTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required PreferenceBinding<double> binding,
    required FocusNode outerNode,
    required FocusNode innerNode,
    required bool focused,
    required ValueChanged<bool> onFocusChange,
    required double min,
    required double max,
    required int divisions,
    required double step,
    required String Function(double) labelBuilder,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<double>(
      valueListenable: binding,
      builder: (context, value, _) => Focus(
        focusNode: outerNode,
        onFocusChange: onFocusChange,
        onKeyEvent: (node, event) => _sliderKeyHandler(
          node: node,
          event: event,
          binding: binding,
          min: min,
          max: max,
          step: step,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: focused ? Colors.white : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTileTheme.merge(
            textColor: focused ? Colors.black87 : Colors.white,
            iconColor: focused ? Colors.black54 : Colors.white70,
            child: ListTile(
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              leading: Icon(icon),
              title: Text(label),
              subtitle: Slider(
                focusNode: innerNode,
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                label: labelBuilder(value),
                onChanged: (v) => binding.value = v,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorPickerTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final Preference<int> preference;
  final bool allowTransparent;

  const _ColorPickerTile({
    required this.title,
    required this.icon,
    required this.preference,
    this.allowTransparent = true,
  });

  @override
  State<_ColorPickerTile> createState() => _ColorPickerTileState();
}

class _ColorPickerTileState extends State<_ColorPickerTile> {
  late final PreferenceBinding<int> _binding;
  bool _pickerOpen = false;

  static const _presetColors = {
    'White': 0xFFFFFFFF,
    'Black': 0xFF000000,
    'Yellow': 0xFFFFFF00,
    'Green': 0xFF00FF00,
    'Cyan': 0xFF00FFFF,
    'Red': 0xFFFF0000,
    'Transparent': 0x00000000,
    'Semi-transparent Black': 0x80000000,
  };

  @override
  void initState() {
    super.initState();
    _binding =
        PreferenceBinding(GetIt.instance<PreferenceStore>(), widget.preference);
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
          leading: Icon(widget.icon),
          title: Text(widget.title),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Color(value),
              shape: BoxShape.circle,
              border: Border.fromBorderSide(ThemeRegistry.active.borders.chipBorder),
            ),
          ),
          onTap: () => _showPicker(context),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) async {
    if (_pickerOpen) return;
    _pickerOpen = true;
    final current = _binding.value;
    final isTV = PlatformDetection.isTV;
    final entries = widget.allowTransparent
        ? _presetColors.entries
        : _presetColors.entries.where((e) => (e.value >> 24) & 0xFF != 0);
    var picked = false;
    final result = await showFocusRestoringDialog<int>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => SimpleDialog(
        title: Text(widget.title),
        children: entries.map((e) {
          final selected = e.value == current;
          return TvFocusHighlight(
            builder: (_, _) => ListTile(
              autofocus: isTV && selected,
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(e.value),
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(ThemeRegistry.active.borders.chipBorder),
                ),
              ),
              title: Text(e.key),
              trailing: selected ? const Icon(Icons.check) : null,
              onTap: () {
                if (picked) return;
                picked = true;
                Navigator.pop(ctx, e.value);
              },
            ),
          );
        }).toList(),
      ),
    );
    if (!mounted) return;
    _pickerOpen = false;
    if (result == null || result == _binding.value) return;
    _binding.value = result;
  }
}
