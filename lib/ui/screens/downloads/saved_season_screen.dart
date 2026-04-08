import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/offline_database.dart';
import '../../../data/providers/offline_providers.dart';
import '../../../data/repositories/offline_repository.dart';
import '../../../data/services/storage_path_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../playback/offline_playback_launcher.dart';
import '../../widgets/offline_image.dart';

class SavedSeasonScreen extends ConsumerWidget {
  final String seasonId;

  const SavedSeasonScreen({
    super.key,
    required this.seasonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonAsync = ref.watch(downloadedItemProvider(seasonId));
    final episodesAsync = ref.watch(downloadedSeasonEpisodesProvider(seasonId));

    final seasonName = seasonAsync.valueOrNull?.name ?? AppLocalizations.of(context).season;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, seasonName),
            Expanded(
              child: episodesAsync.when(
                data: (episodes) => _buildEpisodeList(context, episodes),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(AppLocalizations.of(context).errorLoadingEpisodes, style: const TextStyle(color: Colors.redAccent)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeList(BuildContext context, List<DownloadedItem> episodes) {
    if (episodes.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noDownloadedEpisodes,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: episodes.length,
      itemBuilder: (context, index) => _EpisodeRow(
        episode: episodes[index],
        onTap: () => launchOfflinePlayback(context, episodes[index], episodeQueue: episodes),
        onDelete: () => _deleteEpisode(context, episodes[index]),
      ),
    );
  }

  Future<void> _deleteEpisode(BuildContext context, DownloadedItem episode) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteEpisode),
        content: Text(l10n.removeName(episode.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repo = GetIt.instance<OfflineRepository>();
    if (episode.localFilePath != null) {
      final file = File(episode.localFilePath!);
      if (await file.exists()) await file.delete();
    }
    final imageDir = await GetIt.instance<StoragePathService>().getImageCacheDir();
    final itemImageDir = Directory('${imageDir.path}/${episode.itemId}');
    if (await itemImageDir.exists()) await itemImageDir.delete(recursive: true);

    await repo.deleteItem(episode.itemId);
  }
}

class _EpisodeRow extends StatelessWidget {
  final DownloadedItem episode;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EpisodeRow({required this.episode, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final metadata = _parseMetadata(episode.metadataJson);
    final runtime = metadata['RunTimeTicks'] as int?;
    final durationMin = runtime != null ? (runtime / 600000000).round() : null;
    final overview = metadata['Overview'] as String? ?? '';
    final progress = episode.playbackPositionTicks > 0 && runtime != null && runtime > 0
        ? episode.playbackPositionTicks / runtime
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onDelete,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 160,
                height: 90,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    OfflineImage(
                      localPath: episode.thumbPath ?? episode.posterPath,
                      width: 160,
                      height: 90,
                    ),
                    if (progress != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 3,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF00A4DC)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _episodeLabel(context),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    episode.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  if (durationMin != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context).durationMinutes(durationMin),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                    ),
                  ],
                  if (overview.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _episodeLabel(BuildContext context) {
    final s = episode.parentIndexNumber;
    final e = episode.indexNumber;
    if (s != null && e != null) return AppLocalizations.of(context).seasonEpisodeLabel(s, e);
    if (e != null) return AppLocalizations.of(context).episodeNumber(e);
    return '';
  }

  Map<String, dynamic> _parseMetadata(String json) {
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
