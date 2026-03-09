import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../widgets/settings/preference_tiles.dart';

class AuthSettingsScreen extends StatelessWidget {
  const AuthSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Authentication')),
      body: ListView(
        children: [
          EnumPreferenceTile<UserSelectBehavior>(
            preference: UserPreferences.autoLoginUserBehavior,
            title: 'Auto Login',
            icon: Icons.login,
            labelOf: (v) => switch (v) {
              UserSelectBehavior.disabled => 'Disabled',
              UserSelectBehavior.lastUser => 'Last User',
              UserSelectBehavior.specificUser => 'Specific User',
            },
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.alwaysAuthenticate,
            title: 'Always Authenticate',
            subtitle: 'Require password even with stored token',
            icon: Icons.security,
          ),
          SwitchPreferenceTile(
            preference: UserPreferences.confirmExit,
            title: 'Confirm Exit',
            subtitle: 'Show confirmation before exiting',
            icon: Icons.exit_to_app,
          ),
        ],
      ),
    );
  }
}
