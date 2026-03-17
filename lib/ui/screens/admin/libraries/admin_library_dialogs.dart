import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

Future<void> showRenameLibraryDialog(
  BuildContext context, {
  required String currentName,
  required VoidCallback onRenamed,
}) async {
  final controller = TextEditingController(text: currentName);
  final newName = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Rename Library'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'New name',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
          child: const Text('Rename'),
        ),
      ],
    ),
  );
  controller.dispose();

  if (newName == null ||
      newName.isEmpty ||
      newName == currentName ||
      !context.mounted) {
    return;
  }

  try {
    await GetIt.instance<MediaServerClient>()
        .adminLibraryApi
        .renameVirtualFolder(currentName, newName, refreshLibrary: true);
    onRenamed();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Library renamed to "$newName"')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to rename: $e')),
      );
    }
  }
}

Future<void> showDeleteLibraryDialog(
  BuildContext context, {
  required String libraryName,
  required VoidCallback onDeleted,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Library'),
      content: RichText(
        text: TextSpan(
          style: Theme.of(ctx).textTheme.bodyMedium,
          children: [
            const TextSpan(
                text:
                    'Are you sure you want to delete the library '),
            TextSpan(
              text: libraryName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(
                text:
                    '?\n\nThis will remove the library from Jellyfin but will NOT delete any files on disk.'),
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
        .adminLibraryApi
        .removeVirtualFolder(libraryName, refreshLibrary: true);
    onDeleted();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Library "$libraryName" deleted')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete library: $e')),
      );
    }
  }
}
