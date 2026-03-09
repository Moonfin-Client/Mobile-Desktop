import 'package:flutter/material.dart';

import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_tiles.dart';

class MediaBarSettingsScreen extends StatelessWidget {
  const MediaBarSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media Bar')),
      body: ListView(
        children: [
          SwitchPreferenceTile(
            preference: UserPreferences.mediaBarEnabled,
            title: 'Enable Media Bar',
            subtitle: 'Show featured content slideshow on home',
            icon: Icons.featured_play_list,
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.mediaBarContentType,
            title: 'Content Type',
            icon: Icons.category,
            options: const {
              'both': 'Movies & TV Shows',
              'movies': 'Movies Only',
              'tvshows': 'TV Shows Only',
            },
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.mediaBarItemCount,
            title: 'Item Count',
            icon: Icons.format_list_numbered,
            options: const {
              '5': '5',
              '10': '10',
              '15': '15',
              '20': '20',
            },
          ),
          SliderPreferenceTile(
            preference: UserPreferences.mediaBarOverlayOpacity,
            title: 'Overlay Opacity',
            icon: Icons.opacity,
            min: 0,
            max: 100,
            divisions: 20,
            labelOf: (v) => '$v%',
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.mediaBarOverlayColor,
            title: 'Overlay Color',
            icon: Icons.color_lens,
            options: const {
              'black': 'Black',
              'gray': 'Gray',
              'blue': 'Blue',
              'purple': 'Purple',
              'red': 'Red',
              'green': 'Green',
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.mediaBarTrailerPreview,
            title: 'Trailer Preview',
            subtitle: 'Auto-play trailer previews',
            icon: Icons.play_circle,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.episodePreviewEnabled,
            title: 'Episode Preview',
            subtitle: 'Show episode previews',
            icon: Icons.ondemand_video,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.previewAudioEnabled,
            title: 'Preview Audio',
            subtitle: 'Enable audio in previews',
            icon: Icons.volume_up,
          ),
        ],
      ),
    );
  }
}
