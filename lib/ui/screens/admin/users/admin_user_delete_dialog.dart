import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

Future<void> showAdminUserDeleteDialog(
  BuildContext context, {
  required ServerUser user,
  required VoidCallback onDeleted,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete User'),
      content: RichText(
        text: TextSpan(
          style: Theme.of(ctx).textTheme.bodyMedium,
          children: [
            const TextSpan(text: 'Are you sure you want to delete '),
            TextSpan(
              text: user.name ?? 'this user',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '? This cannot be undone.'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await GetIt.instance<MediaServerClient>()
        .adminUsersApi
        .deleteUser(user.id);
    onDeleted();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User "${user.name}" deleted')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
    }
  }
}
