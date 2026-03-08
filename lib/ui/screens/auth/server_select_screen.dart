import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/destinations.dart';

class ServerSelectScreen extends StatefulWidget {
  const ServerSelectScreen({super.key});

  @override
  State<ServerSelectScreen> createState() => _ServerSelectScreenState();
}

class _ServerSelectScreenState extends State<ServerSelectScreen> {
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _connectToServer() {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;
    context.go('${Destinations.login}?serverId=new');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.play_circle_filled,
                size: 64,
                color: Color(0xFF00A4DC),
              ),
              const SizedBox(height: 16),
              const Text(
                'Connect to Server',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Server Address',
                  hintText: 'https://your-server.example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.dns),
                ),
                keyboardType: TextInputType.url,
                onSubmitted: (_) => _connectToServer(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _connectToServer,
                child: const Text('Connect'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.search),
                label: const Text('Discover Servers'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
