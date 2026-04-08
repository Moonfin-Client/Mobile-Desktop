import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../data/models/aggregated_item.dart';
import '../../data/repositories/offline_repository.dart';
import '../../data/services/download_service.dart';
import '../../l10n/app_localizations.dart';
import 'focusable_dialog_row.dart';

class TrackActionDialog extends StatelessWidget {
  final AggregatedItem track;
  final VoidCallback? onPlay;
  final VoidCallback? onPlayNext;
  final VoidCallback? onAddToQueue;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onRemoveFromPlaylist;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onGoToAlbum;
  final VoidCallback? onGoToArtist;

  const TrackActionDialog({
    super.key,
    required this.track,
    this.onPlay,
    this.onPlayNext,
    this.onAddToQueue,
    this.onAddToPlaylist,
    this.onRemoveFromPlaylist,
    this.onMoveUp,
    this.onMoveDown,
    this.onToggleFavorite,
    this.onGoToAlbum,
    this.onGoToArtist,
  });

  static Future<void> show(
    BuildContext context, {
    required AggregatedItem track,
    VoidCallback? onPlay,
    VoidCallback? onPlayNext,
    VoidCallback? onAddToQueue,
    VoidCallback? onAddToPlaylist,
    VoidCallback? onRemoveFromPlaylist,
    VoidCallback? onMoveUp,
    VoidCallback? onMoveDown,
    VoidCallback? onToggleFavorite,
    VoidCallback? onGoToAlbum,
    VoidCallback? onGoToArtist,
  }) {
    return showDialog(
      context: context,
      builder: (_) => TrackActionDialog(
        track: track,
        onPlay: onPlay,
        onPlayNext: onPlayNext,
        onAddToQueue: onAddToQueue,
        onAddToPlaylist: onAddToPlaylist,
        onRemoveFromPlaylist: onRemoveFromPlaylist,
        onMoveUp: onMoveUp,
        onMoveDown: onMoveDown,
        onToggleFavorite: onToggleFavorite,
        onGoToAlbum: onGoToAlbum,
        onGoToArtist: onGoToArtist,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final downloadService = GetIt.instance<DownloadService>();
    final offlineRepo = GetIt.instance<OfflineRepository>();

    return StreamBuilder(
      stream: offlineRepo.watchItem(track.id),
      builder: (context, snapshot) => ListenableBuilder(
        listenable: downloadService,
        builder: (context, _) {
          final offlineItem = snapshot.data;
          final isDownloaded =
              offlineItem?.downloadStatus == 2 && offlineItem?.localFilePath != null;
          final isDownloading = downloadService.isDownloading(track.id);
          final supportsOffline = _supportsOfflineActions(track);

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(minWidth: 340, maxWidth: 440),
              decoration: BoxDecoration(
                color: const Color(0xE6141414),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (track.artists.isNotEmpty)
                            Text(
                              track.artists.join(', '),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          else if (track.albumArtist != null)
                            Text(
                              track.albumArtist!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                  const SizedBox(height: 8),
                  if (onPlay != null)
                    FocusableDialogRow(
                      icon: Icons.play_arrow,
                      label: l10n.play,
                      onTap: () { Navigator.pop(context); onPlay!(); },
                      autofocus: true,
                    ),
                  if (onPlayNext != null)
                    FocusableDialogRow(
                      icon: Icons.queue_play_next,
                      label: l10n.trackActionPlayNext,
                      onTap: () { Navigator.pop(context); onPlayNext!(); },
                    ),
                  if (onAddToQueue != null)
                    FocusableDialogRow(
                      icon: Icons.add_to_queue,
                      label: l10n.trackActionAddToQueue,
                      onTap: () { Navigator.pop(context); onAddToQueue!(); },
                    ),
                  if (onAddToPlaylist != null)
                    FocusableDialogRow(
                      icon: Icons.playlist_add,
                      label: l10n.trackActionAddToPlaylist,
                      onTap: () { Navigator.pop(context); onAddToPlaylist!(); },
                    ),
                  if (supportsOffline && !isDownloaded && !isDownloading)
                    FocusableDialogRow(
                      icon: Icons.download,
                      label: l10n.download,
                      onTap: () {
                        Navigator.pop(context);
                        downloadService.downloadItem(track);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.trackActionDownloading(track.name)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  if (supportsOffline && isDownloading)
                    FocusableDialogRow(
                      icon: Icons.close,
                      label: l10n.trackActionCancelDownload,
                      onTap: () {
                        Navigator.pop(context);
                        downloadService.cancelDownload(track.id);
                      },
                    ),
                  if (supportsOffline && isDownloaded)
                    FocusableDialogRow(
                      icon: Icons.delete_outline,
                      label: l10n.deleteDownloaded,
                      onTap: () async {
                        final capturedL10n = l10n;
                        Navigator.pop(context);
                        final success = await downloadService.deleteDownloadedFiles(track);
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? capturedL10n.trackActionDeletedFile
                                  : capturedL10n.trackActionDeleteFileFailed,
                            ),
                          ),
                        );
                      },
                    ),
                  if (onRemoveFromPlaylist != null)
                    FocusableDialogRow(
                      icon: Icons.playlist_remove,
                      label: l10n.trackActionDeleteFromPlaylist,
                      onTap: () { Navigator.pop(context); onRemoveFromPlaylist!(); },
                    ),
                  if (onMoveUp != null)
                    FocusableDialogRow(
                      icon: Icons.arrow_upward,
                      label: l10n.trackActionMoveUp,
                      onTap: () { Navigator.pop(context); onMoveUp!(); },
                    ),
                  if (onMoveDown != null)
                    FocusableDialogRow(
                      icon: Icons.arrow_downward,
                      label: l10n.trackActionMoveDown,
                      onTap: () { Navigator.pop(context); onMoveDown!(); },
                    ),
                  if (onToggleFavorite != null)
                    FocusableDialogRow(
                      icon: track.isFavorite ? Icons.favorite : Icons.favorite_border,
                      label: track.isFavorite ? l10n.trackActionRemoveFromFavorites : l10n.trackActionAddToFavorites,
                      onTap: () { Navigator.pop(context); onToggleFavorite!(); },
                    ),
                  if (onGoToAlbum != null)
                    FocusableDialogRow(
                      icon: Icons.album,
                      label: l10n.trackActionGoToAlbum,
                      onTap: () { Navigator.pop(context); onGoToAlbum!(); },
                    ),
                  if (onGoToArtist != null)
                    FocusableDialogRow(
                      icon: Icons.person,
                      label: l10n.trackActionGoToArtist,
                      onTap: () { Navigator.pop(context); onGoToArtist!(); },
                    ),
                  const SizedBox(height: 4),
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                  const SizedBox(height: 4),
                  FocusableDialogRow(
                    label: l10n.cancel,
                    onTap: () => Navigator.pop(context),
                    dimmed: true,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _supportsOfflineActions(AggregatedItem item) {
    final mediaType = item.rawData['MediaType'] as String?;
    return item.type == 'Audio' || item.type == 'AudioBook' || mediaType == 'Audio';
  }
}
