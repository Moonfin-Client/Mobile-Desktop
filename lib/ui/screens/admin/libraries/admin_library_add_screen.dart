import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/admin_user_providers.dart';
import '../widgets/filesystem_browser.dart';

class AdminLibraryAddScreen extends ConsumerStatefulWidget {
  const AdminLibraryAddScreen({super.key});

  @override
  ConsumerState<AdminLibraryAddScreen> createState() =>
      _AdminLibraryAddScreenState();
}

class _AdminLibraryAddScreenState
    extends ConsumerState<AdminLibraryAddScreen> {
  int _step = 0;
  String? _collectionType;
  final _nameController = TextEditingController();
  final List<String> _paths = [];
  bool _saving = false;

  static const _collectionTypes = <String, (String, IconData)>{
    'movies': ('Movies', Icons.movie),
    'tvshows': ('TV Shows', Icons.tv),
    'music': ('Music', Icons.music_note),
    'musicvideos': ('Music Videos', Icons.music_video),
    'books': ('Books', Icons.book),
    'photos': ('Photos', Icons.photo),
    'homevideos': ('Home Videos', Icons.videocam),
    'mixed': ('Mixed Content', Icons.folder),
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectType(String type) {
    setState(() {
      _collectionType = type;
      final label = _collectionTypes[type]?.$1 ?? type;
      if (_nameController.text.isEmpty) {
        _nameController.text = label;
      }
      _step = 1;
    });
  }

  void _addPath(String path) {
    if (!_paths.contains(path)) {
      setState(() => _paths.add(path));
    }
  }

  void _removePath(int index) {
    setState(() => _paths.removeAt(index));
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminLibraryNameRequired)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await GetIt.instance<MediaServerClient>()
          .adminLibraryApi
          .addVirtualFolder(
            name: name,
            collectionType:
                _collectionType == 'mixed' ? null : _collectionType,
            paths: _paths.isEmpty ? null : _paths,
            refreshLibrary: true,
          );
      ref.invalidate(adminLibrariesProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminLibraryCreateFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.adminAddLibrary,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          _buildStepper(),
          const SizedBox(height: 16),
          Expanded(child: _buildStepContent()),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    const labels = ['Type', 'Name', 'Paths', 'Confirm'];
    return Row(
      children: List.generate(labels.length, (i) {
        final isCurrent = i == _step;
        final isDone = i < _step;
        return Expanded(
          child: GestureDetector(
            onTap: isDone ? () => setState(() => _step = i) : null,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isCurrent
                      ? Theme.of(context).colorScheme.primary
                      : isDone
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: isDone
                      ? Icon(Icons.check, size: 14,
                          color: Theme.of(context).colorScheme.onPrimaryContainer)
                      : Text('${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isCurrent
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          )),
                ),
                const SizedBox(height: 4),
                Text(labels[i],
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildTypeStep();
      case 1:
        return _buildNameStep();
      case 2:
        return _buildPathsStep();
      case 3:
        return _buildConfirmStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTypeStep() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: _collectionTypes.entries.map((entry) {
        final isSelected = _collectionType == entry.key;
        return Card(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: InkWell(
            onTap: () => _selectType(entry.key),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(entry.value.$2, size: 28),
                  const SizedBox(width: 12),
                  Flexible(child: Text(entry.value.$1)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNameStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: l10n.adminLibraryName,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _step = 0),
              child: Text(l10n.back),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                if (_nameController.text.trim().isEmpty) return;
                setState(() => _step = 2);
              },
              child: Text(l10n.next),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPathsStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_paths.isNotEmpty) ...[
          Text(l10n.adminSelectedPaths,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...List.generate(_paths.length, (i) => ListTile(
            leading: const Icon(Icons.folder),
            title: Text(_paths[i],
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _removePath(i),
            ),
            dense: true,
          )),
          const Divider(),
        ],
        Text(l10n.adminBrowseFilesystem,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Expanded(
          child: FilesystemBrowser(
            onPathSelected: _addPath,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _step = 1),
              child: Text(l10n.back),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => setState(() => _step = 3),
              child: Text(l10n.next),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _summaryRow('Type',
                    _collectionTypes[_collectionType]?.$1 ?? 'Mixed Content'),
                const SizedBox(height: 8),
                _summaryRow('Name', _nameController.text.trim()),
                const SizedBox(height: 8),
                Text(l10n.paths,
                    style: Theme.of(context).textTheme.titleSmall),
                if (_paths.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(l10n.adminNoPathsAdded,
                        style: const TextStyle(fontStyle: FontStyle.italic)),
                  )
                else
                  ...(_paths).map((p) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(p,
                            style: const TextStyle(
                                fontFamily: 'monospace', fontSize: 13)),
                      )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton(
              onPressed: _saving ? null : () => setState(() => _step = 2),
              child: Text(l10n.back),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _saving ? null : _create,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.adminCreateLibrary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(label,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
