import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';

class FilesystemBrowser extends StatefulWidget {
  final String? initialPath;
  final ValueChanged<String> onPathSelected;

  const FilesystemBrowser({
    super.key,
    this.initialPath,
    required this.onPathSelected,
  });

  @override
  State<FilesystemBrowser> createState() => _FilesystemBrowserState();
}

class _FilesystemBrowserState extends State<FilesystemBrowser> {
  late final AdminEnvironmentApi _envApi;
  final _pathController = TextEditingController();

  List<Map<String, dynamic>> _entries = [];
  List<String> _breadcrumbs = [];
  String _currentPath = '';
  bool _loading = true;
  String? _error;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _envApi = GetIt.instance<MediaServerClient>().adminEnvironmentApi;
    if (widget.initialPath != null && widget.initialPath!.isNotEmpty) {
      _currentPath = widget.initialPath!;
      _pathController.text = _currentPath;
      _loadDirectory(_currentPath);
    } else {
      _loadDrives();
    }
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  List<String> _buildBreadcrumbs(String path) {
    if (path.isEmpty) return [];
    final parts = <String>[];
    var current = path;
    while (current.isNotEmpty) {
      parts.insert(0, current);
      final sepIndex = current.lastIndexOf('/');
      final backslashIndex = current.lastIndexOf('\\');
      final lastSep =
          sepIndex > backslashIndex ? sepIndex : backslashIndex;
      if (lastSep <= 0) break;
      current = current.substring(0, lastSep);
    }
    return parts;
  }

  Future<void> _loadDrives() async {
    setState(() {
      _loading = true;
      _error = null;
      _validationError = null;
    });
    try {
      final drives = await _envApi.getDrives();
      if (!mounted) return;
      setState(() {
        _entries = drives;
        _currentPath = '';
        _breadcrumbs = [];
        _pathController.text = '';
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

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _loading = true;
      _error = null;
      _validationError = null;
    });
    try {
      final contents = await _envApi.getDirectoryContents(
        path,
        includeDirectories: true,
        includeFiles: false,
      );
      if (!mounted) return;
      setState(() {
        _entries = contents;
        _currentPath = path;
        _breadcrumbs = _buildBreadcrumbs(path);
        _pathController.text = path;
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

  Future<void> _navigateUp() async {
    if (_currentPath.isEmpty) return;
    final parent = await _envApi.getParentPath(_currentPath);
    if (!mounted) return;
    if (parent == null || parent.isEmpty) {
      _loadDrives();
    } else {
      _loadDirectory(parent);
    }
  }

  Future<void> _validateAndSelect() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) return;
    setState(() => _validationError = null);
    try {
      await _envApi.validatePath(path);
      if (!mounted) return;
      widget.onPathSelected(path);
    } catch (e) {
      if (!mounted) return;
      setState(() => _validationError = 'Invalid path: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _pathController,
                decoration: InputDecoration(
                  labelText: l10n.path,
                  border: const OutlineInputBorder(),
                  errorText: _validationError,
                  isDense: true,
                ),
                onSubmitted: (_) => _validateAndSelect(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _validateAndSelect,
              child: Text(l10n.select),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildBreadcrumbBar(),
        const Divider(height: 1),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(l10n.failedToLoad, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: _currentPath.isEmpty
                      ? _loadDrives
                      : () => _loadDirectory(_currentPath),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                final name = entry['Name'] as String? ?? '';
                final path = entry['Path'] as String? ?? '';
                final isDir = (entry['Type'] as String?) == 'Directory' ||
                    entry['IsDirectory'] == true;
                return ListTile(
                  leading: Icon(isDir ? Icons.folder : Icons.storage),
                  title: Text(name),
                  subtitle: path != name ? Text(path, style: const TextStyle(fontSize: 12)) : null,
                  dense: true,
                  onTap: () => _loadDirectory(path),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBreadcrumbBar() {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          TextButton.icon(
            onPressed: _loadDrives,
            icon: const Icon(Icons.computer, size: 16),
            label: Text(l10n.root),
          ),
          if (_currentPath.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.arrow_upward, size: 16),
              onPressed: _navigateUp,
              tooltip: l10n.up,
              visualDensity: VisualDensity.compact,
            ),
            ..._breadcrumbs.map((crumb) {
              final label = crumb.split(RegExp(r'[/\\]')).last;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_right, size: 16),
                  TextButton(
                    onPressed: () => _loadDirectory(crumb),
                    child: Text(label.isEmpty ? crumb : label),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}
