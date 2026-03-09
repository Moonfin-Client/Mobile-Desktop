import 'package:flutter/material.dart';

import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_tiles.dart';

class MoonfinSettingsScreen extends StatelessWidget {
  const MoonfinSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moonfin Settings')),
      body: ListView(
        children: [
          SwitchPreferenceTile(
            preference: UserPreferences.showShuffleButton,
            title: 'Show Shuffle Button',
            icon: Icons.shuffle,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showGenresButton,
            title: 'Show Genres Button',
            icon: Icons.category,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showFavoritesButton,
            title: 'Show Favorites Button',
            icon: Icons.favorite,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showLibrariesInToolbar,
            title: 'Show Libraries in Toolbar',
            icon: Icons.video_library,
          ),
          const Divider(),
          SwitchPreferenceTile(
            preference: UserPreferences.themeMusicEnabled,
            title: 'Theme Music',
            subtitle: 'Play theme music on detail pages',
            icon: Icons.music_note,
          ),
          SliderPreferenceTile(
            preference: UserPreferences.themeMusicVolume,
            title: 'Theme Music Volume',
            icon: Icons.volume_up,
            min: 0,
            max: 100,
            divisions: 20,
            labelOf: (v) => '$v%',
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.themeMusicOnHomeRows,
            title: 'Theme Music on Home Rows',
            subtitle: 'Play when browsing home screen',
            icon: Icons.queue_music,
          ),
          const Divider(),
          StringPickerPreferenceTile(
            preference: UserPreferences.seasonalSurprise,
            title: 'Seasonal Effects',
            icon: Icons.celebration,
            options: const {
              'none': 'None',
              'snow': 'Snow',
              'fireworks': 'Fireworks',
              'confetti': 'Confetti',
              'leaves': 'Falling Leaves',
            },
          ),
          const Divider(),
          SwitchPreferenceTile(
            preference: UserPreferences.enableAdditionalRatings,
            title: 'Additional Ratings',
            subtitle: 'Show MDBList and TMDB ratings',
            icon: Icons.star,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.showRatingLabels,
            title: 'Rating Labels',
            subtitle: 'Show labels next to rating icons',
            icon: Icons.label,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.enableEpisodeRatings,
            title: 'Episode Ratings',
            subtitle: 'Show ratings on individual episodes',
            icon: Icons.stars,
          ),
          const Divider(),
          SwitchPreferenceTile(
            preference: UserPreferences.pluginSyncEnabled,
            title: 'Server Plugin Sync',
            subtitle: 'Sync settings with Moonfin server plugin',
            icon: Icons.sync,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.updateNotificationsEnabled,
            title: 'Update Notifications',
            subtitle: 'Show when updates are available',
            icon: Icons.system_update,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.debuggingEnabled,
            title: 'Debug Mode',
            subtitle: 'Enable debug logging',
            icon: Icons.bug_report,
          ),
        ],
      ),
    );
  }
}
