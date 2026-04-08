import 'package:flutter/material.dart';

import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_tiles.dart';
import '../../../l10n/app_localizations.dart';

class ScreensaverSettingsScreen extends StatelessWidget {
  const ScreensaverSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.screensaver)),
      body: ListView(
        children: [
          SwitchPreferenceTile(
            preference: UserPreferences.screensaverInAppEnabled,
            title: l10n.inAppScreensaver,
            subtitle: l10n.enableBuiltInScreensaver,
            icon: Icons.dark_mode,
          ),
          StringPickerPreferenceTile(
            preference: UserPreferences.screensaverMode,
            title: l10n.mode,
            icon: Icons.style,
            options: {
              'library': l10n.libraryArt,
              'logo': l10n.logo,
              'clock': l10n.clock,
            },
          ),
          SliderPreferenceTile(
            preference: UserPreferences.screensaverInAppTimeout,
            title: l10n.timeout,
            icon: Icons.timer,
            min: 60000,
            max: 1800000,
            divisions: 29,
            labelOf: (v) {
              final minutes = v ~/ 60000;
              return l10n.minutesShort(minutes);
            },
          ),
          SliderPreferenceTile(
            preference: UserPreferences.screensaverDimmingLevel,
            title: l10n.dimmingLevel,
            icon: Icons.brightness_low,
            min: 0,
            max: 100,
            divisions: 20,
            labelOf: (v) => l10n.percentValue(v),
          ),
          SliderPreferenceTile(
            preference: UserPreferences.screensaverAgeRatingMax,
            title: l10n.maxAgeRating,
            icon: Icons.child_care,
            min: 0,
            max: 18,
            divisions: 18,
            labelOf: (v) => v == 0 ? l10n.any : l10n.agePlusValue(v),
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.screensaverAgeRatingRequired,
            title: l10n.requireAgeRating,
            subtitle: l10n.onlyShowRatedContent,
            icon: Icons.verified_user,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.screensaverShowClock,
            title: l10n.showClock,
            subtitle: l10n.displayClockDuringScreensaver,
            icon: Icons.access_time,
          ),
        ],
      ),
    );
  }
}
