import 'package:flutter/material.dart';

import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/settings/preference_tiles.dart';

class AuthSettingsScreen extends StatelessWidget {
  const AuthSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.authentication)),
      body: ListView(
        children: [
          EnumPreferenceTile<UserSelectBehavior>(
            preference: UserPreferences.autoLoginUserBehavior,
            title: l10n.autoLogin,
            icon: Icons.login,
            labelOf: (v) => switch (v) {
              UserSelectBehavior.disabled => l10n.disabled,
              UserSelectBehavior.lastUser => l10n.lastUser,
              UserSelectBehavior.specificUser => l10n.specificUser,
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.alwaysAuthenticate,
            title: l10n.alwaysAuthenticate,
            subtitle: l10n.requirePasswordWithToken,
            icon: Icons.security,
          ),
          if (!PlatformDetection.isMobile)
            SwitchPreferenceTile(
              preference: UserPreferences.confirmExit,
              title: l10n.confirmExit,
              subtitle: l10n.showConfirmationBeforeExiting,
              icon: Icons.exit_to_app,
            ),
        ],
      ),
    );
  }
}
