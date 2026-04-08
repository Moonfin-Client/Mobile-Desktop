import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../navigation/destinations.dart';
import '../providers/admin_user_providers.dart';
import 'admin_user_delete_dialog.dart';
import '../../../../l10n/app_localizations.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _toggleUserDisabled(ServerUser user) async {
    final l10n = AppLocalizations.of(context);
    final currentPolicy = user.policy ?? const UserPolicy();
    final willDisable = !currentPolicy.isDisabled;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(willDisable ? l10n.adminDisableUser : l10n.adminEnableUser),
        content: Text(
          willDisable
              ? l10n.adminDisableUserConfirm(user.name ?? '')
              : l10n.adminEnableUserConfirm(user.name ?? ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(willDisable ? l10n.disable : l10n.enable),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final updatedPolicy = currentPolicy.toJson()
        ..['IsDisabled'] = willDisable;
      await GetIt.instance<MediaServerClient>()
          .adminUsersApi
          .updateUserPolicy(user.id, updatedPolicy);

      ref.invalidate(adminUsersListProvider);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            willDisable
                ? l10n.adminUserDisabled(user.name ?? '')
                : l10n.adminUserEnabled(user.name ?? ''),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminUserPolicyUpdateFailed(e.toString()))),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final usersAsync = ref.watch(adminUsersListProvider);
    final client = GetIt.instance<MediaServerClient>();

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.adminUsersLoadFailed,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('$e', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => ref.invalidate(adminUsersListProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (users) {
        final theme = Theme.of(context);
        final bottomSafe = MediaQuery.of(context).padding.bottom;
        final listBottomPadding = bottomSafe + 108;
        final fabBottom = bottomSafe + 16;
        final filtered = users.where((user) {
          if (_searchQuery.isEmpty) {
            return true;
          }
          final query = _searchQuery.toLowerCase();
          return (user.name ?? '').toLowerCase().contains(query);
        }).toList();

        return Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value.trim()),
                  decoration: InputDecoration(
                    hintText: l10n.adminSearchUsers,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
            ? Center(
                child: Text(
                  users.isEmpty ? 'No users found' : 'No users match your search',
                ),
              )
            : ListView.builder(
              padding: EdgeInsets.fromLTRB(8, 8, 8, listBottomPadding),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final user = filtered[index];
                  final policy = user.policy;
                  final isAdmin = policy?.isAdministrator ?? false;
                  final isDisabled = policy?.isDisabled ?? false;
                  final hasRemoteAccess = policy?.enableRemoteAccess ?? false;
                  final isHidden = policy?.isHidden ?? false;
                  final displayName = (user.name ?? 'Unknown').trim();
                  final initials = displayName.isEmpty
                      ? '?'
                      : displayName.characters.first.toUpperCase();

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push(Destinations.adminUser(user.id)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 21,
                                  backgroundImage: user.primaryImageTag != null
                                      ? NetworkImage(client.imageApi.getUserImageUrl(user.id))
                                      : null,
                                  child: user.primaryImageTag == null
                                      ? Text(
                                          initials,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          decoration: isDisabled
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: isDisabled
                                              ? theme.disabledColor
                                              : null,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user.hasPassword
                                            ? 'Password set'
                                            : 'No password configured',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: l10n.adminEditUser,
                                  onPressed: () => context.push(Destinations.adminUser(user.id)),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (isAdmin) _statusChip(context, 'Admin', Icons.shield),
                                if (isDisabled)
                                  _statusChip(
                                    context,
                                    'Disabled',
                                    Icons.block,
                                    tint: theme.colorScheme.error,
                                  ),
                                _statusChip(
                                  context,
                                  hasRemoteAccess ? 'Remote Access' : 'Local Only',
                                  hasRemoteAccess ? Icons.cloud_done : Icons.cloud_off,
                                ),
                                if (isHidden)
                                  _statusChip(
                                    context,
                                    'Hidden',
                                    Icons.visibility_off,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => context.push(Destinations.adminUser(user.id)),
                                  icon: const Icon(Icons.manage_accounts_outlined, size: 18),
                                  label: Text(l10n.manage),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _toggleUserDisabled(user),
                                  icon: Icon(
                                    isDisabled
                                        ? Icons.check_circle_outline
                                        : Icons.block,
                                    size: 18,
                                  ),
                                  label: Text(isDisabled ? l10n.enable : l10n.disable),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: theme.colorScheme.error,
                                  ),
                                  onPressed: () => showAdminUserDeleteDialog(
                                    context,
                                    user: user,
                                    onDeleted: () =>
                                        ref.invalidate(adminUsersListProvider),
                                  ),
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  label: Text(l10n.delete),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: fabBottom,
            child: FloatingActionButton.extended(
              onPressed: () => context.push(Destinations.adminUsersAdd),
              icon: const Icon(Icons.person_add),
              label: Text(l10n.adminAddUser),
            ),
          ),
        ],
      );
      },
    );
  }

  Widget _statusChip(
    BuildContext context,
    String label,
    IconData icon, {
    Color? tint,
  }) {
    final theme = Theme.of(context);
    final base = tint ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: base.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: base),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: base,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
