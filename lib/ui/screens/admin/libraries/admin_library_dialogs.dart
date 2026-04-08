import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';

Future<void> showRenameLibraryDialog(
  BuildContext context, {
  required String currentName,
  required VoidCallback onRenamed,
}) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: currentName);
  final newName = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.adminRenameLibrary),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: l10n.adminNewName,
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
        onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
          child: Text(l10n.rename),
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
        SnackBar(content: Text(l10n.adminLibraryRenamed(newName))),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminRenameFailed(e.toString()))),
      );
    }
  }
}

Future<void> showDeleteLibraryDialog(
  BuildContext context, {
  required String libraryName,
  required VoidCallback onDeleted,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.adminDeleteLibrary),
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
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.delete),
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
        SnackBar(content: Text(l10n.adminLibraryDeleted(libraryName))),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminLibraryDeleteFailed(e.toString()))),
      );
    }
  }
}
