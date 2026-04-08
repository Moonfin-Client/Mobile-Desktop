import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/admin_user_providers.dart';

class AdminRepositoriesScreen extends ConsumerStatefulWidget {
  const AdminRepositoriesScreen({super.key});

  @override
  ConsumerState<AdminRepositoriesScreen> createState() =>
      _AdminRepositoriesScreenState();
}

class _AdminRepositoriesScreenState
    extends ConsumerState<AdminRepositoriesScreen> {
  bool _saving = false;

  AdminPluginsApi get _api =>
      GetIt.instance<MediaServerClient>().adminPluginsApi;

  Future<void> _addRepository() async {
    final result = await showDialog<RepositoryInfo>(
      context: context,
      builder: (context) => const _RepositoryDialog(),
    );
    if (result == null || !mounted) return;

    final current =
        ref.read(adminRepositoriesProvider).valueOrNull ?? <RepositoryInfo>[];
    await _saveRepos([...current, result]);
  }

  Future<void> _editRepository(int index, RepositoryInfo repo) async {
    final result = await showDialog<RepositoryInfo>(
      context: context,
      builder: (context) => _RepositoryDialog(existing: repo),
    );
    if (result == null || !mounted) return;

    final current = List<RepositoryInfo>.from(
      ref.read(adminRepositoriesProvider).valueOrNull ?? [],
    );
    current[index] = result;
    await _saveRepos(current);
  }

  Future<void> _removeRepository(int index, RepositoryInfo repo) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.adminRemoveRepository),
            content: Text(
              l10n.adminRemoveRepositoryConfirm(repo.name.isNotEmpty ? repo.name : repo.url),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.adminReposRemove),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;

    final current = List<RepositoryInfo>.from(
      ref.read(adminRepositoriesProvider).valueOrNull ?? [],
    );
    current.removeAt(index);
    await _saveRepos(current);
  }

  Future<void> _toggleRepository(int index) async {
    final current = List<RepositoryInfo>.from(
      ref.read(adminRepositoriesProvider).valueOrNull ?? [],
    );
    final repo = current[index];
    current[index] = RepositoryInfo(
      name: repo.name,
      url: repo.url,
      enabled: !repo.enabled,
    );
    await _saveRepos(current);
  }

  Future<void> _saveRepos(List<RepositoryInfo> repos) async {
    setState(() => _saving = true);
    try {
      await _api.setRepositories(repos);
      ref.invalidate(adminRepositoriesProvider);
      ref.invalidate(adminAvailablePackagesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).adminRepositoriesSaveFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reposAsync = ref.watch(adminRepositoriesProvider);

    return reposAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context).adminRepositoriesLoadFailed(error.toString())),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => ref.invalidate(adminRepositoriesProvider),
                  child: Text(AppLocalizations.of(context).retry),
                ),
              ],
            ),
          ),
      data: (repos) => _buildContent(context, repos),
    );
  }

  Widget _buildContent(BuildContext context, List<RepositoryInfo> repos) {
    final theme = Theme.of(context);
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final listBottomPadding = bottomSafe + 96;
    final fabBottom = bottomSafe + 16;

    return Stack(
      children: [
        if (repos.isEmpty)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.source,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).adminReposEmpty,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).adminReposEmptySubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            padding: EdgeInsets.only(bottom: listBottomPadding),
            itemCount: repos.length,
            itemBuilder: (context, index) {
              final repo = repos[index];
              return _RepositoryTile(
                repo: repo,
                onEdit: () => _editRepository(index, repo),
                onRemove: () => _removeRepository(index, repo),
                onToggle: () => _toggleRepository(index),
              );
            },
          ),
        if (_saving) const Center(child: CircularProgressIndicator()),
        Positioned(
          right: 16,
          bottom: fabBottom,
          child: FloatingActionButton(
            onPressed: _addRepository,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _RepositoryTile extends StatelessWidget {
  final RepositoryInfo repo;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onToggle;

  const _RepositoryTile({
    required this.repo,
    required this.onEdit,
    required this.onRemove,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        Icons.source,
        color:
            repo.enabled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        repo.name.isNotEmpty ? repo.name : AppLocalizations.of(context).adminReposUnnamed,
        style: TextStyle(
          color: repo.enabled ? null : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        repo.url,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color:
              repo.enabled
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: repo.enabled, onChanged: (_) => onToggle()),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                case 'remove':
                  onRemove();
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(context).edit)),
                  PopupMenuItem(value: 'remove', child: Text(AppLocalizations.of(context).adminReposRemove)),
                ],
          ),
        ],
      ),
    );
  }
}

class _RepositoryDialog extends StatefulWidget {
  final RepositoryInfo? existing;
  const _RepositoryDialog({this.existing});

  @override
  State<_RepositoryDialog> createState() => _RepositoryDialogState();
}

class _RepositoryDialogState extends State<_RepositoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late bool _enabled;
  bool _urlNotEmpty = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _urlController = TextEditingController(text: widget.existing?.url ?? '');
    _enabled = widget.existing?.enabled ?? true;
    _urlNotEmpty = _urlController.text.trim().isNotEmpty;
    _urlController.addListener(_onUrlChanged);
  }

  void _onUrlChanged() {
    final notEmpty = _urlController.text.trim().isNotEmpty;
    if (notEmpty != _urlNotEmpty) {
      setState(() => _urlNotEmpty = notEmpty);
    }
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final dialogWidth = (MediaQuery.sizeOf(context).width - 32).clamp(
      280.0,
      400.0,
    );
    return AlertDialog(
      title: Text(isEdit ? AppLocalizations.of(context).adminReposEditTitle : AppLocalizations.of(context).adminReposAddTitle),
      content: SizedBox(
        width: dialogWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).name,
                hintText: AppLocalizations.of(context).adminRepositoryNameHint,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).adminRepositoryUrl,
                hintText:
                    'https://repo.jellyfin.org/files/plugin/manifest.json',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context).enabled),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        FilledButton(
          onPressed:
              !_urlNotEmpty
                  ? null
                  : () {
                    Navigator.pop(
                      context,
                      RepositoryInfo(
                        name: _nameController.text.trim(),
                        url: _urlController.text.trim(),
                        enabled: _enabled,
                      ),
                    );
                  },
          child: Text(isEdit ? AppLocalizations.of(context).save : AppLocalizations.of(context).add),
        ),
      ],
    );
  }
}
