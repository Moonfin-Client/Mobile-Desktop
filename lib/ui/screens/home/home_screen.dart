import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/destinations.dart';
import '../../widgets/responsive_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moonfin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(Destinations.search),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(Destinations.settings),
          ),
        ],
      ),
      body: const ResponsiveLayout(
        mobileBody: _HomeContent(),
        tvBody: _HomeContentTV(),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildSection(context, 'Continue Watching'),
        _buildSection(context, 'Next Up'),
        _buildSection(context, 'Latest Media'),
        _buildSection(context, 'My Libraries'),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 180,
          child: Center(
            child: Text(
              'No items',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeContentTV extends StatelessWidget {
  const _HomeContentTV();

  @override
  Widget build(BuildContext context) {
    return const _HomeContent();
  }
}
