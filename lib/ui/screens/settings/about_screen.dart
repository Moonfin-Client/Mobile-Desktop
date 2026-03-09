import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        children: [
          const SizedBox(height: 32),
          const Icon(Icons.play_circle_filled, size: 64, color: Color(0xFF00A4DC)),
          const SizedBox(height: 16),
          const Center(
            child: Text('Moonfin', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          const Center(child: Text('Version 0.1.0')),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Open Source Licenses'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Moonfin',
              applicationVersion: '0.1.0',
              applicationIcon: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.play_circle_filled, size: 48, color: Color(0xFF00A4DC)),
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('Source Code'),
            subtitle: Text('github.com/Moonfin-Client/Mobile-Desktop'),
          ),
        ],
      ),
    );
  }
}
