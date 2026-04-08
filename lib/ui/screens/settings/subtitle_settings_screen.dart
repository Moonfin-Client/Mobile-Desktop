import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';

import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_binding.dart';
import '../../widgets/settings/preference_tiles.dart';
import '../../../l10n/app_localizations.dart';

class SubtitleSettingsScreen extends StatefulWidget {
  const SubtitleSettingsScreen({super.key});

  @override
  State<SubtitleSettingsScreen> createState() => _SubtitleSettingsScreenState();
}

class _SubtitleSettingsScreenState extends State<SubtitleSettingsScreen> {
  late final PreferenceBinding<double> _sizeBind;
  late final PreferenceBinding<double> _offsetBind;

  @override
  void initState() {
    super.initState();
    final store = GetIt.instance<PreferenceStore>();
    _sizeBind = PreferenceBinding(store, UserPreferences.subtitlesTextSize);
    _offsetBind = PreferenceBinding(store, UserPreferences.subtitlesOffsetPosition);
  }

  @override
  void dispose() {
    _sizeBind.dispose();
    _offsetBind.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.subtitles)),
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
            builder: (context, value, _) => ListTile(
              leading: const Icon(Icons.format_size),
              title: Text(l10n.subtitleSize),
              subtitle: Slider(
                value: value.clamp(12.0, 48.0),
                min: 12,
                max: 48,
                divisions: 18,
                label: l10n.pixelValue(value.round()),
                onChanged: (v) => _sizeBind.value = v,
              ),
            ),
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
            builder: (context, value, _) => ListTile(
              leading: const Icon(Icons.vertical_align_bottom),
              title: Text(l10n.verticalOffset),
              subtitle: Slider(
                value: value.clamp(0.0, 0.5),
                min: 0.0,
                max: 0.5,
                divisions: 50,
                label: l10n.percentValue((value * 100).round()),
                onChanged: (v) => _offsetBind.value = v,
              ),
            ),
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

  void _showPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(widget.title),
        children: _presetColors.entries.map((e) {
          return ListTile(
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
            onTap: () {
              _binding.value = e.value;
              Navigator.pop(ctx);
            },
          );
        }).toList(),
      ),
    );
  }
}
