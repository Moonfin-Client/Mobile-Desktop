import 'package:flutter/material.dart';

import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_tiles.dart';

class ScreensaverSettingsScreen extends StatelessWidget {
  const ScreensaverSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screensaver')),
      body: ListView(
        children: [
          SwitchPreferenceTile(
            preference: UserPreferences.screensaverInAppEnabled,
            title: 'In-App Screensaver',
            subtitle: 'Enable the built-in screensaver',
            icon: Icons.dark_mode,
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.screensaverMode,
            title: 'Mode',
            icon: Icons.style,
            options: const {
              'library': 'Library Art',
              'logo': 'Logo',
              'clock': 'Clock',
            },
          ),
          SliderPreferenceTile(
            preference: UserPreferences.screensaverInAppTimeout,
            title: 'Timeout',
            icon: Icons.timer,
            min: 60000,
            max: 1800000,
            divisions: 29,
            labelOf: (v) {
              final minutes = v ~/ 60000;
              return '$minutes min';
            },
          ),
          SliderPreferenceTile(
            preference: UserPreferences.screensaverDimmingLevel,
            title: 'Dimming Level',
            icon: Icons.brightness_low,
            min: 0,
            max: 100,
            divisions: 20,
            labelOf: (v) => '$v%',
          ),
          SliderPreferenceTile(
            preference: UserPreferences.screensaverAgeRatingMax,
            title: 'Max Age Rating',
            icon: Icons.child_care,
            min: 0,
            max: 18,
            divisions: 18,
            labelOf: (v) => v == 0 ? 'Any' : '$v+',
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.screensaverAgeRatingRequired,
            title: 'Require Age Rating',
            subtitle: 'Only show rated content',
            icon: Icons.verified_user,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.screensaverShowClock,
            title: 'Show Clock',
            subtitle: 'Display clock during screensaver',
            icon: Icons.access_time,
          ),
        ],
      ),
    );
  }
}
