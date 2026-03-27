// example/lib/main.dart
//
// RAR Archive Browser - A two-pane file browser for RAR archives.
// Features:
// - Open RAR button to select archives
// - Two-pane layout on wide screens, tabs on narrow screens (<800px)
// - File tree with expandable folders
// - Content viewer for text and images

import 'package:flutter/material.dart';

import 'file_browser.dart';
import 'services/archive_service.dart';

void main() {
  runApp(const RarBrowserApp());
}

class RarBrowserApp extends StatelessWidget {
  const RarBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAR Browser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const RarBrowserPage(),
    );
  }
}

class RarBrowserPage extends StatefulWidget {
  const RarBrowserPage({super.key});

  @override
  State<RarBrowserPage> createState() => _RarBrowserPageState();
}

class _RarBrowserPageState extends State<RarBrowserPage> {
  final _archiveService = ArchiveService();
  FileNode? _root;
  bool _isLoading = false;
  String? _error;
  String? _warning;
  String? _archiveName;
  String? _extractPath;
  String? _password;
  String? _rarVersion;

  @override
  void initState() {
    super.initState();
    _archiveService.requestPermissions();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _openRarFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _warning = null;
      _rarVersion = null;
    });

    final result = await _archiveService.pickAndOpenArchive(
      password: _password,
    );

    if (result == null) {
      setState(() => _isLoading = false);
      return;
    }

    if (!result.isSuccess) {
      setState(() {
        _error = result.errorMessage ?? 'Failed to open archive';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _root = FileNode.buildTree(
        result.files,
        rootName: result.archiveName ?? 'Archive',
      );
      _archiveName = result.archiveName;
      _extractPath = result.extractPath;
      _rarVersion = result.rarVersion;
      _warning = result.errorMessage; // Warning message if any
      _isLoading = false;
    });
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String password = _password ?? '';
        return AlertDialog(
          title: const Text('Archive Password'),
          content: TextField(
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Enter password (leave empty for none)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => password = value,
            controller: TextEditingController(text: _password),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _password = null);
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () {
                setState(() => _password = password.isEmpty ? null : password);
                Navigator.pop(context);
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_archiveName ?? 'RAR Browser'),
        actions: [
          IconButton(
            icon: Icon(_password != null ? Icons.lock : Icons.lock_open),
            tooltip: 'Set password',
            onPressed: _showPasswordDialog,
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _openRarFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Open RAR'),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Opening archive...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _openRarFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_root == null) {
      return _buildEmptyState();
    }

    return FileBrowser(
      root: _root!,
      title: _archiveName ?? 'File Browser',
      rarVersion: _rarVersion,
      warning: _warning,
      onLoadContent: (path) async {
        if (_extractPath == null) return null;
        final fullPath = '$_extractPath/$path';
        return _archiveService.loadContent(fullPath);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.archive, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 24),
          Text(
            'RAR Archive Browser',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Open a RAR file to browse its contents',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _openRarFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('Open RAR File'),
          ),
          const SizedBox(height: 16),
          Text(
            'Supports RAR v4 and v5 formats',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
