import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';

import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_binding.dart';
import '../../widgets/settings/preference_tiles.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Subtitles')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Style settings (size, color, offset) apply to text-based subtitles '
              '(SRT, VTT, TTML). ASS/SSA subtitles use their own embedded styling '
              'unless "ASS/SSA Direct Play" is turned off. '
              'Bitmap subtitles (PGS, DVB, VobSub) cannot be restyled.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.defaultSubtitleLanguage,
            title: 'Default Subtitle Language',
            icon: Icons.language,
            options: const {
              '': 'None',
              'eng': 'English',
              'spa': 'Spanish',
              'fra': 'French',
              'deu': 'German',
              'ita': 'Italian',
              'por': 'Portuguese',
              'jpn': 'Japanese',
              'kor': 'Korean',
              'zho': 'Chinese',
              'rus': 'Russian',
              'ara': 'Arabic',
              'hin': 'Hindi',
              'nld': 'Dutch',
              'swe': 'Swedish',
              'nor': 'Norwegian',
              'dan': 'Danish',
              'fin': 'Finnish',
              'pol': 'Polish',
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.subtitlesDefaultToNone,
            title: 'Default to No Subtitles',
            subtitle: 'Turn off subtitles by default',
            icon: Icons.subtitles_off,
          ),
          ValueListenableBuilder<double>(
            valueListenable: _sizeBind,
            builder: (context, value, _) => ListTile(
              leading: const Icon(Icons.format_size),
              title: const Text('Subtitle Size'),
              subtitle: Slider(
                value: value.clamp(12.0, 48.0),
                min: 12,
                max: 48,
                divisions: 18,
                label: '${value.round()}px',
                onChanged: (v) => _sizeBind.value = v,
              ),
            ),
          ),
          _ColorPickerTile(
            title: 'Text Color',
            icon: Icons.format_color_text,
            preference: UserPreferences.subtitlesTextColor,
          ),
          _ColorPickerTile(
            title: 'Background Color',
            icon: Icons.format_color_fill,
            preference: UserPreferences.subtitlesBackgroundColor,
          ),
          _ColorPickerTile(
            title: 'Stroke Color',
            icon: Icons.border_color,
            preference: UserPreferences.subtitleTextStrokeColor,
          ),
          ValueListenableBuilder<double>(
            valueListenable: _offsetBind,
            builder: (context, value, _) => ListTile(
              leading: const Icon(Icons.vertical_align_bottom),
              title: const Text('Vertical Offset'),
              subtitle: Slider(
                value: value.clamp(0.0, 0.5),
                min: 0.0,
                max: 0.5,
                divisions: 50,
                label: '${(value * 100).round()}%',
                onChanged: (v) => _offsetBind.value = v,
              ),
            ),
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.pgsDirectPlay,
            title: 'PGS Direct Play',
            subtitle: 'Direct play PGS subtitles',
            icon: Icons.image,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.assDirectPlay,
            title: 'ASS/SSA Direct Play',
            subtitle: 'Direct play ASS/SSA subtitles',
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
