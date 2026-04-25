import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';

import '../../../preference/user_preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../../../util/platform_detection.dart';
import '../../widgets/overlay_sheet.dart';
import '../../widgets/settings/preference_binding.dart';
import '../../widgets/settings/preference_tiles.dart';
import 'settings_app_bar.dart';
import '../../widgets/focus/request_initial_focus.dart';

class SubtitleSettingsScreen extends StatefulWidget {
  const SubtitleSettingsScreen({super.key});

  @override
  State<SubtitleSettingsScreen> createState() => _SubtitleSettingsScreenState();
}

class _SubtitleSettingsScreenState extends State<SubtitleSettingsScreen> {
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
    _offsetBind = PreferenceBinding(store, UserPreferences.subtitlesOffsetPosition);
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
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
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
      appBar: buildSettingsAppBar(context, Text(l10n.subtitles)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              l10n.subtitleStyleDescription,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.defaultSubtitleLanguage,
            title: l10n.defaultSubtitleLanguage,
            icon: Icons.language,
            options: {
              '': l10n.none,
              'eng': l10n.english,
              'spa': l10n.spanish,
              'fra': l10n.french,
              'deu': l10n.german,
              'ita': l10n.italian,
              'por': l10n.portuguese,
              'jpn': l10n.japanese,
              'kor': l10n.korean,
              'zho': l10n.chinese,
              'rus': l10n.russian,
              'ara': l10n.arabic,
              'hin': l10n.hindi,
              'nld': l10n.dutch,
              'swe': l10n.swedish,
              'nor': l10n.norwegian,
              'dan': l10n.danish,
              'fin': l10n.finnish,
              'pol': l10n.polish,
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.subtitlesDefaultToNone,
            title: l10n.defaultToNoSubtitles,
            subtitle: l10n.turnOffSubtitlesByDefault,
            icon: Icons.subtitles_off,
          ),
          ValueListenableBuilder<double>(
            valueListenable: _sizeBind,
            builder: (context, value, _) {
              final colorScheme = Theme.of(context).colorScheme;
              return Focus(
                focusNode: _sizeOuterNode,
                onFocusChange: (focused) {
                  if (_sizeFocused != focused && mounted) {
                    setState(() => _sizeFocused = focused);
                  }
                },
                onKeyEvent: (node, event) => _sliderKeyHandler(
                  node: node,
                  event: event,
                  binding: _sizeBind,
                  min: 12,
                  max: 48,
                  step: 2,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: _sizeFocused ? Colors.white : colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTileTheme.merge(
                    textColor: _sizeFocused ? Colors.black87 : Colors.white,
                    iconColor: _sizeFocused ? Colors.black54 : Colors.white70,
                    child: ListTile(
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      leading: const Icon(Icons.format_size),
                      title: Text(l10n.subtitleSize),
                      subtitle: Slider(
                        focusNode: _sizeInnerNode,
                        value: value.clamp(12.0, 48.0),
                        min: 12,
                        max: 48,
                        divisions: 18,
                        label: l10n.pixelValue(value.round()),
                        onChanged: (v) => _sizeBind.value = v,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          _ColorPickerTile(
            title: l10n.textColor,
            icon: Icons.format_color_text,
            preference: UserPreferences.subtitlesTextColor,
          ),
          _ColorPickerTile(
            title: l10n.backgroundColor,
            icon: Icons.format_color_fill,
            preference: UserPreferences.subtitlesBackgroundColor,
          ),
          _ColorPickerTile(
            title: l10n.strokeColor,
            icon: Icons.border_color,
            preference: UserPreferences.subtitleTextStrokeColor,
          ),
          ValueListenableBuilder<double>(
            valueListenable: _offsetBind,
            builder: (context, value, _) {
              final colorScheme = Theme.of(context).colorScheme;
              return Focus(
                focusNode: _offsetOuterNode,
                onFocusChange: (focused) {
                  if (_offsetFocused != focused && mounted) {
                    setState(() => _offsetFocused = focused);
                  }
                },
                onKeyEvent: (node, event) => _sliderKeyHandler(
                  node: node,
                  event: event,
                  binding: _offsetBind,
                  min: 0.0,
                  max: 0.5,
                  step: 0.01,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: _offsetFocused ? Colors.white : colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTileTheme.merge(
                    textColor: _offsetFocused ? Colors.black87 : Colors.white,
                    iconColor: _offsetFocused ? Colors.black54 : Colors.white70,
                    child: ListTile(
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      leading: const Icon(Icons.vertical_align_bottom),
                      title: Text(l10n.verticalOffset),
                      subtitle: Slider(
                        focusNode: _offsetInnerNode,
                        value: value.clamp(0.0, 0.5),
                        min: 0.0,
                        max: 0.5,
                        divisions: 50,
                        label: l10n.percentValue((value * 100).round()),
                        onChanged: (v) => _offsetBind.value = v,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.pgsDirectPlay,
            title: l10n.pgsDirectPlay,
            subtitle: l10n.directPlayPgsSubtitles,
            icon: Icons.image,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.assDirectPlay,
            title: l10n.assSsaDirectPlay,
            subtitle: l10n.directPlayAssSsaSubtitles,
            icon: Icons.text_snippet,
          ),
        ],
      ),
    );
  }
}

class _ColorPickerTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final Preference<int> preference;

  const _ColorPickerTile({
    required this.title,
    required this.icon,
    required this.preference,
  });

  @override
  State<_ColorPickerTile> createState() => _ColorPickerTileState();
}

class _ColorPickerTileState extends State<_ColorPickerTile> {
  late final PreferenceBinding<int> _binding;

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
    _binding = PreferenceBinding(GetIt.instance<PreferenceStore>(), widget.preference);
  }

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _binding,
      builder: (context, value, _) => ListTile(
        leading: Icon(widget.icon),
        title: Text(widget.title),
        trailing: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Color(value),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
        ),
        onTap: () => _showPicker(context),
      ),
    );
  }

  void _showPicker(BuildContext context) async {
    final current = _binding.value;
    final isTV = PlatformDetection.isTV;
    final result = await showFocusRestoringDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(widget.title),
        children: _presetColors.entries.map((e) {
          final selected = e.value == current;
          return TvFocusHighlight(
            builder: (_, __) => ListTile(
              autofocus: isTV && selected,
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(e.value),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
              ),
              title: Text(e.key),
              trailing: selected ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, e.value),
            ),
          );
        }).toList(),
      ),
    );
    if (!mounted || result == null || result == _binding.value) return;
    _binding.value = result;
  }
}
