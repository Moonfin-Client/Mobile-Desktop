import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_preference/jellyfin_preference.dart';

import '../../widgets/settings/preference_binding.dart';
import '../../widgets/settings/preference_tiles.dart';

class JellyseerrConfigScreen extends StatefulWidget {
  const JellyseerrConfigScreen({super.key});

  @override
  State<JellyseerrConfigScreen> createState() => _JellyseerrConfigScreenState();
}

class _JellyseerrConfigScreenState extends State<JellyseerrConfigScreen> {
  late final PreferenceBinding<String> _urlBinding;
  late final TextEditingController _urlController;

  static const _jellyseerrUrl = Preference(
    key: 'jellyseerr_url',
    defaultValue: '',
  );

  static const _jellyseerrEnabled = Preference(
    key: 'jellyseerr_enabled',
    defaultValue: false,
  );

  static const _jellyseerrNsfw = Preference(
    key: 'jellyseerr_nsfw_filter',
    defaultValue: true,
  );

  static const _jellyseerrAuthMethod = Preference(
    key: 'jellyseerr_auth_method',
    defaultValue: 'sso',
  );

  @override
  void initState() {
    super.initState();
    final store = GetIt.instance<PreferenceStore>();
    _urlBinding = PreferenceBinding(store, _jellyseerrUrl);
    _urlController = TextEditingController(text: _urlBinding.value);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlBinding.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jellyseerr')),
      body: ListView(
        children: [
          SwitchPreferenceTile(
            preference: _jellyseerrEnabled,
            title: 'Enable Jellyseerr',
            subtitle: 'Show Jellyseerr in navigation',
            icon: Icons.movie_filter,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Jellyseerr URL',
                hintText: 'https://jellyseerr.example.com',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              onChanged: (v) => _urlBinding.value = v.trim(),
            ),
          ),
          StringPickerPreferenceTile(
            preference: _jellyseerrAuthMethod,
            title: 'Auth Method',
            icon: Icons.vpn_key,
            options: const {
              'sso': 'SSO (Single Sign-On)',
              'local': 'Local Account',
            },
          ),
          SwitchPreferenceTile(
            preference: _jellyseerrNsfw,
            title: 'NSFW Filter',
            subtitle: 'Hide adult content in results',
            icon: Icons.visibility_off,
          ),
        ],
      ),
    );
  }
}
