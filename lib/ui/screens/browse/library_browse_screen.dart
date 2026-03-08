import 'package:flutter/material.dart';

class LibraryBrowseScreen extends StatelessWidget {
  final String libraryId;

  const LibraryBrowseScreen({super.key, required this.libraryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: const Center(
        child: Text('Library content will appear here'),
      ),
    );
  }
}
