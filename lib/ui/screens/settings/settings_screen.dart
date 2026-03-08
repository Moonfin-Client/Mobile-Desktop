import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SettingsSection(title: 'Playback'),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Max Streaming Bitrate'),
            subtitle: const Text('Auto'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.subtitles),
            title: const Text('Default Subtitle Language'),
            subtitle: const Text('None'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.audiotrack),
            title: const Text('Default Audio Language'),
            subtitle: const Text('None'),
            onTap: () {},
          ),
          const _SettingsSection(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home Sections'),
            subtitle: const Text('Configure home screen layout'),
            onTap: () {},
          ),
          const _SettingsSection(title: 'Account'),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Switch Server'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () {},
          ),
          const _SettingsSection(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Version'),
            subtitle: Text('0.1.0'),
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
