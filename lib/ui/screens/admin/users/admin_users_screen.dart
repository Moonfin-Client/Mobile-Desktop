import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../navigation/destinations.dart';
import '../providers/admin_user_providers.dart';
import 'admin_user_delete_dialog.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersListProvider);
    final client = GetIt.instance<MediaServerClient>();

    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load users',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('$e', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => ref.invalidate(adminUsersListProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (users) => Stack(
        children: [
          users.isEmpty
            ? const Center(child: Text('No users found'))
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isAdmin =
                      user.policy?.isAdministrator ?? false;
                  final isDisabled = user.policy?.isDisabled ?? false;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.primaryImageTag != null
                            ? NetworkImage(
                                client.imageApi.getUserImageUrl(user.id))
                            : null,
                        child: user.primaryImageTag == null
                            ? Text(
                                (user.name ?? '?')[0].toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name ?? 'Unknown',
                              style: TextStyle(
                                decoration: isDisabled
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isDisabled
                                    ? Theme.of(context).disabledColor
                                    : null,
                              ),
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.shield,
                                size: 16,
                                color:
                                    Theme.of(context).colorScheme.primary),
                          ],
                          if (isDisabled) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.block,
                                size: 16,
                                color: Theme.of(context).colorScheme.error),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        user.hasPassword ? 'Password set' : 'No password',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              context
                                  .go(Destinations.adminUser(user.id));
                            case 'delete':
                              showAdminUserDeleteDialog(
                                context,
                                user: user,
                                onDeleted: () =>
                                    ref.invalidate(adminUsersListProvider),
                              );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete),
                              title: Text('Delete'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      onTap: () =>
                          context.go(Destinations.adminUser(user.id)),
                    ),
                  );
                },
              ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => context.go(Destinations.adminUsersAdd),
              icon: const Icon(Icons.person_add),
              label: const Text('Add User'),
            ),
          ),
        ],
      ),
    );
  }
}
