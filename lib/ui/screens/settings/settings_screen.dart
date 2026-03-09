import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/destinations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SettingsSection(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Authentication'),
            subtitle: const Text('Auto login, server management'),
            onTap: () => context.push(Destinations.settingsAuth),
          ),
          ListTile(
            leading: const Icon(Icons.pin),
            title: const Text('PIN Code'),
            subtitle: const Text('Set up PIN code protection'),
            onTap: () => context.push(Destinations.settingsPinCode),
          ),
          const _SettingsSection(title: 'Customization'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme & Appearance'),
            subtitle: const Text('Focus color, watched indicators'),
            onTap: () => context.push(Destinations.settingsAppearance),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home Sections'),
            subtitle: const Text('Reorder and toggle home rows'),
            onTap: () => context.push(Destinations.settingsHomeSections),
          ),
          const _SettingsSection(title: 'Moonfin'),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Moonfin Settings'),
            subtitle: const Text('Navbar, theme music, seasonal'),
            onTap: () => context.push(Destinations.settingsMoonfin),
          ),
          ListTile(
            leading: const Icon(Icons.featured_play_list),
            title: const Text('Media Bar'),
            subtitle: const Text('Content, appearance, trailers'),
            onTap: () => context.push(Destinations.settingsMediaBar),
          ),
          ListTile(
            leading: const Icon(Icons.movie_filter),
            title: const Text('Jellyseerr'),
            subtitle: const Text('Connection, auth, NSFW filter'),
            onTap: () => context.push(Destinations.settingsJellyseerr),
          ),
          ListTile(
            leading: const Icon(Icons.child_care),
            title: const Text('Parental Controls'),
            subtitle: const Text('Content rating restrictions'),
            onTap: () => context.push(Destinations.settingsParental),
          ),
          const _SettingsSection(title: 'Playback'),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Playback'),
            subtitle: const Text('Bitrate, resolution, behavior'),
            onTap: () => context.push(Destinations.settingsPlayback),
          ),
          ListTile(
            leading: const Icon(Icons.subtitles),
            title: const Text('Subtitles'),
            subtitle: const Text('Language, size, appearance'),
            onTap: () => context.push(Destinations.settingsSubtitles),
          ),
          const _SettingsSection(title: 'Display'),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Screensaver'),
            subtitle: const Text('Mode, timeout, dimming'),
            onTap: () => context.push(Destinations.settingsScreensaver),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Library Display'),
            subtitle: const Text('Poster size, image type'),
            onTap: () => context.push(Destinations.settingsLibrary),
          ),
          const _SettingsSection(title: 'Other'),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Switch Server'),
            onTap: () => context.go(Destinations.serverSelect),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () => context.go(Destinations.serverSelect),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('Version, licenses'),
            onTap: () => context.push(Destinations.settingsAbout),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;

  const _SettingsSection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
