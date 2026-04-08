import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../navigation/destinations.dart';
import '../providers/admin_user_providers.dart';
import 'admin_library_dialogs.dart';

class AdminLibrariesScreen extends ConsumerWidget {
  const AdminLibrariesScreen({super.key});

  static const _collectionIcons = <String, IconData>{
    'movies': Icons.movie,
    'tvshows': Icons.tv,
    'music': Icons.music_note,
    'musicvideos': Icons.music_video,
    'books': Icons.book,
    'photos': Icons.photo,
    'homevideos': Icons.videocam,
    'boxsets': Icons.collections,
    'playlists': Icons.playlist_play,
    'mixed': Icons.folder,
  };

  static IconData iconForType(String? type) =>
      _collectionIcons[type?.toLowerCase()] ?? Icons.folder;

  static const _collectionLabels = <String, String>{
    'movies': 'Movies',
    'tvshows': 'TV Shows',
    'music': 'Music',
    'musicvideos': 'Music Videos',
    'books': 'Books',
    'photos': 'Photos',
    'homevideos': 'Home Videos',
    'boxsets': 'Collections',
    'playlists': 'Playlists',
  };

  static String labelForType(String? type) =>
      type == null
          ? 'Mixed Content'
          : _collectionLabels[type.toLowerCase()] ?? type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final listBottomPadding = bottomSafe + 120;
    final actionsBottom = bottomSafe + 16;
    final librariesAsync = ref.watch(adminLibrariesProvider);

    return librariesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.adminLibrariesLoadFailed,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('$e', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () => ref.invalidate(adminLibrariesProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
      data: (libraries) => Stack(
        children: [
          libraries.isEmpty
              ? Center(child: Text(l10n.adminNoLibraries))
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(8, 8, 8, listBottomPadding),
                  itemCount: libraries.length,
                  itemBuilder: (context, index) {
                    final lib = libraries[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(iconForType(lib.collectionType)),
                        ),
                        title: Text(lib.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              labelForType(lib.collectionType),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (lib.locations.isNotEmpty)
                              Text(
                                lib.locations.join(', '),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        fontFamily: 'monospace',
                                        fontSize: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        isThreeLine: lib.locations.isNotEmpty,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) =>
                              _onAction(context, ref, value, lib),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: const Icon(Icons.edit),
                                title: Text(l10n.edit),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'rename',
                              child: ListTile(
                                leading: const Icon(Icons.drive_file_rename_outline),
                                title: Text(l10n.rename),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: const Icon(Icons.delete),
                                title: Text(l10n.delete),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        onTap: () =>
                            context.push(Destinations.adminLibrary(lib.itemId)),
                      ),
                    );
                  },
                ),
          Positioned(
            right: 16,
            bottom: actionsBottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'scan',
                  tooltip: l10n.adminScanAllLibraries,
                  onPressed: () => _scanAll(context),
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  heroTag: 'add',
                  onPressed: () => context.push(Destinations.adminLibrariesAdd),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.adminAddLibrary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onAction(
      BuildContext context, WidgetRef ref, String action, VirtualFolderInfo lib) {
    switch (action) {
      case 'edit':
        context.push(Destinations.adminLibrary(lib.itemId));
      case 'rename':
        showRenameLibraryDialog(
          context,
          currentName: lib.name,
          onRenamed: () => ref.invalidate(adminLibrariesProvider),
        );
      case 'delete':
        showDeleteLibraryDialog(
          context,
          libraryName: lib.name,
          onDeleted: () => ref.invalidate(adminLibrariesProvider),
        );
    }
  }

  Future<void> _scanAll(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      await GetIt.instance<MediaServerClient>()
          .adminLibraryApi
          .refreshLibrary();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminLibraryScanStarted)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminScanFailed(e.toString()))),
        );
      }
    }
  }
}
