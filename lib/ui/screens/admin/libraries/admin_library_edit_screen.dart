import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../providers/admin_user_providers.dart';
import '../widgets/filesystem_browser.dart';

class AdminLibraryEditScreen extends ConsumerStatefulWidget {
  final String libraryId;
  const AdminLibraryEditScreen({super.key, required this.libraryId});

  @override
  ConsumerState<AdminLibraryEditScreen> createState() =>
      _AdminLibraryEditScreenState();
}

class _AdminLibraryEditScreenState
    extends ConsumerState<AdminLibraryEditScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final MediaServerClient _client;

  VirtualFolderInfo? _library;
  late List<String> _paths;
  late Map<String, dynamic> _options;

  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _showBrowser = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _client = GetIt.instance<MediaServerClient>();
    _paths = [];
    _options = {};
    _loadLibrary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final folders = await _client.adminLibraryApi.getVirtualFolders();
      if (!mounted) return;
      final lib = folders.firstWhere(
        (f) => f.itemId == widget.libraryId,
        orElse: () => throw Exception('Library not found'),
      );
      setState(() {
        _library = lib;
        _paths = List<String>.from(lib.locations);
        _options = Map<String, dynamic>.from(lib.libraryOptions ?? {});
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _addPath(String path) async {
    if (_paths.contains(path)) return;
    setState(() => _saving = true);
    try {
      await _client.adminLibraryApi.addMediaPath(_library!.name, path);
      setState(() => _paths.add(path));
      ref.invalidate(adminLibrariesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add path: $e')),
        );
      }
    } finally {
      if (mounted) setState(() {
        _saving = false;
        _showBrowser = false;
      });
    }
  }

  Future<void> _removePath(String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Path'),
        content: Text('Remove "$path" from this library?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _client.adminLibraryApi
          .removeMediaPath(_library!.name, path, refreshLibrary: true);
      setState(() => _paths.remove(path));
      ref.invalidate(adminLibrariesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove path: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveOptions() async {
    setState(() => _saving = true);
    try {
      await _client.adminLibraryApi
          .updateLibraryOptions(widget.libraryId, _options);
      ref.invalidate(adminLibrariesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Library options saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save options: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load library',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_error!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.tonal(
                onPressed: _loadLibrary, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(_library!.name,
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Paths'),
            Tab(text: 'Options'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPathsTab(),
              _buildOptionsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPathsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._paths.map((path) => ListTile(
              leading: const Icon(Icons.folder),
              title: Text(path,
                  style:
                      const TextStyle(fontFamily: 'monospace', fontSize: 13)),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _saving ? null : () => _removePath(path),
              ),
              dense: true,
            )),
        if (_paths.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No media paths configured'),
          ),
        const Divider(),
        if (!_showBrowser)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => setState(() => _showBrowser = true),
              icon: const Icon(Icons.add),
              label: const Text('Add Path'),
            ),
          )
        else ...[
          Row(
            children: [
              Text('Browse server filesystem:',
                  style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _showBrowser = false),
                child: const Text('Cancel'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 350,
            child: FilesystemBrowser(onPathSelected: _addPath),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _optionSwitch(
          'EnableRealtimeMonitor',
          'Real-time monitoring',
          'Detect file changes automatically',
        ),
        _optionSwitch(
          'EnableChapterImageExtraction',
          'Extract chapter images',
          'Generate images for detected chapters',
        ),
        _optionSwitch(
          'ExtractTrickplayImagesDuringLibraryScan',
          'Extract trickplay images during scan',
          'Generate trickplay images when scanning',
        ),
        _optionSwitch(
          'SaveLocalMetadata',
          'Save artwork into media folders',
          'Store images alongside media files',
        ),
        const SizedBox(height: 16),
        _buildMetadataLanguage(),
        const SizedBox(height: 16),
        _buildMetadataCountry(),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _saving ? null : _saveOptions,
            child: const Text('Save Options'),
          ),
        ),
      ],
    );
  }

  Widget _optionSwitch(String key, String title, String subtitle) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: _options[key] as bool? ?? false,
      onChanged: (v) => setState(() => _options[key] = v),
    );
  }

  Widget _buildMetadataLanguage() {
    final current =
        _options['PreferredMetadataLanguage'] as String? ?? '';
    return TextFormField(
      initialValue: current,
      decoration: const InputDecoration(
        labelText: 'Preferred metadata language',
        hintText: 'e.g. en, de, fr',
        border: OutlineInputBorder(),
      ),
      onChanged: (v) => _options['PreferredMetadataLanguage'] = v,
    );
  }

  Widget _buildMetadataCountry() {
    final current =
        _options['MetadataCountryCode'] as String? ?? '';
    return TextFormField(
      initialValue: current,
      decoration: const InputDecoration(
        labelText: 'Metadata country code',
        hintText: 'e.g. US, DE, FR',
        border: OutlineInputBorder(),
      ),
      onChanged: (v) => _options['MetadataCountryCode'] = v,
    );
  }
}
