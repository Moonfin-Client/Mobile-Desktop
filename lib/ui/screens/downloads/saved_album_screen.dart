import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/offline_database.dart';
import '../../../data/providers/offline_providers.dart';
import '../../../playback/offline_playback_launcher.dart';
import '../../../preference/user_preferences.dart';
import '../../mixins/focus_state_mixin.dart';
import '../../widgets/offline_image.dart';

class SavedAlbumScreen extends ConsumerWidget {
  final String albumId;
  final String? albumName;

  const SavedAlbumScreen({
    super.key,
    required this.albumId,
    this.albumName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(downloadedAudioProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: audio.when(
          data: (items) {
            final tracks = _tracksForAlbum(items, albumId);
            final resolvedName = albumName ?? _resolveAlbumName(tracks) ?? 'Album';

            if (tracks.isEmpty) {
              return _EmptyAlbumState(albumName: resolvedName);
            }

            return Column(
              children: [
                _Header(albumName: resolvedName),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        '${tracks.length} tracks',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => launchOfflinePlayback(
                          context,
                          tracks.first,
                          episodeQueue: tracks,
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play Album'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      final trackNumber = _trackNumber(track) ?? index + 1;
                      return _OfflineTrackTile(
                        track: track,
                        trackNumber: trackNumber,
                        onTap: () => launchOfflinePlayback(
                          context,
                          track,
                          episodeQueue: tracks,
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.white.withValues(alpha: 0.06),
                      height: 1,
                    ),
                    itemCount: tracks.length,
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'Failed to load album: $e',
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  static List<DownloadedItem> _tracksForAlbum(List<DownloadedItem> items, String albumId) {
    final tracks = items.where((item) {
      final metaAlbumId = item.parsedMetadata['AlbumId'] as String?;
      final fallbackAlbumId = 'track:${item.itemId}';
      return (metaAlbumId ?? fallbackAlbumId) == albumId;
    }).toList()
      ..sort((a, b) {
        final aDisc = a.parentIndexNumber ?? 0;
        final bDisc = b.parentIndexNumber ?? 0;
        if (aDisc != bDisc) return aDisc.compareTo(bDisc);

        final aTrack = _trackNumber(a) ?? 0;
        final bTrack = _trackNumber(b) ?? 0;
        if (aTrack != bTrack) return aTrack.compareTo(bTrack);

        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return tracks;
  }

  static int? _trackNumber(DownloadedItem item) {
    final fromMetadata = item.parsedMetadata['IndexNumber'];
    if (fromMetadata is int) return fromMetadata;
    return item.indexNumber;
  }

  static String? _resolveAlbumName(List<DownloadedItem> tracks) {
    if (tracks.isEmpty) return null;
    return tracks.first.parsedMetadata['Album'] as String?;
  }
}

class _Header extends StatelessWidget {
  final String albumName;

  const _Header({required this.albumName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              albumName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAlbumState extends StatelessWidget {
  final String albumName;

  const _EmptyAlbumState({required this.albumName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.album_outlined, size: 64, color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              'No downloaded tracks found for $albumName.',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineTrackTile extends StatefulWidget {
  final DownloadedItem track;
  final int trackNumber;
  final VoidCallback onTap;

  const _OfflineTrackTile({
    required this.track,
    required this.trackNumber,
    required this.onTap,
  });

  @override
  State<_OfflineTrackTile> createState() => _OfflineTrackTileState();
}

class _OfflineTrackTileState extends State<_OfflineTrackTile> with FocusStateMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardExpansion =
        GetIt.instance<UserPreferences>().get(UserPreferences.cardFocusExpansion);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: Focus(
        onFocusChange: (hasFocus) => setFocused(hasFocus),
        child: AnimatedScale(
          scale: cardExpansion && showFocusBorder ? 1.01 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: showFocusBorder
                  ? focusColor.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: showFocusBorder
                  ? Border.all(
                      color: focusColor.withValues(alpha: 0.85),
                      width: 1.25,
                    )
                  : null,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: SizedBox(
                width: 54,
                height: 54,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: OfflineImage(
                    localPath: widget.track.posterPath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(
                widget.track.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: showFocusBorder ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Track ${widget.trackNumber}',
                style: TextStyle(
                  color: showFocusBorder
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.white54,
                  fontSize: 12,
                ),
              ),
              trailing: Icon(
                Icons.play_arrow,
                color: showFocusBorder ? Colors.white : Colors.white70,
              ),
              onTap: widget.onTap,
            ),
          ),
        ),
      ),
    );
  }
}
