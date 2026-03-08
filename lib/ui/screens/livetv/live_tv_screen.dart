import 'package:flutter/material.dart';

class LiveTvScreen extends StatelessWidget {
  const LiveTvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live TV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.fiber_dvr),
            onPressed: () {},
            tooltip: 'Recordings',
          ),
        ],
      ),
      body: const Center(
        child: Text('Live TV guide will appear here'),
      ),
    );
  }
}
