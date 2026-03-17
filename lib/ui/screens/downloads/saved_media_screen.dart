import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/offline_database.dart';
import '../../../data/providers/offline_providers.dart';
import '../../../data/repositories/offline_repository.dart';
import '../../../data/services/storage_path_service.dart';
import '../../../di/providers.dart';
import '../../../playback/offline_playback_launcher.dart';
import '../../navigation/destinations.dart';
import '../../widgets/offline_image.dart';

class SavedMediaScreen extends ConsumerStatefulWidget {
  const SavedMediaScreen({super.key});

  @override
  ConsumerState<SavedMediaScreen> createState() => _SavedMediaScreenState();
}

enum _Filter { all, movies, tvShows }

class _SavedMediaScreenState extends ConsumerState<SavedMediaScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final movies = ref.watch(downloadedMoviesProvider);
    final series = ref.watch(downloadedSeriesProvider);
    final storage = ref.watch(storageUsedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(storage),
            _buildFilterChips(),
            Expanded(child: _buildContent(movies, series)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<int> storage) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.canPop() ? context.pop() : context.go(Destinations.home),
          ),
          const SizedBox(width: 8),
          const Text(
            'Saved Media',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          storage.when(
            data: (bytes) => Text(
              _formatBytes(bytes),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: _Filter.values.map((f) {
          final selected = _filter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_filterLabel(f)),
              selected: selected,
              onSelected: (_) => setState(() => _filter = f),
              selectedColor: Colors.white.withValues(alpha: 0.2),
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 13,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(
    AsyncValue<List<DownloadedItem>> movies,
    AsyncValue<List<DownloadedItem>> series,
  ) {
    final movieList = movies.valueOrNull ?? [];
    final seriesList = series.valueOrNull ?? [];
    final showMovies = _filter != _Filter.tvShows;
    final showSeries = _filter != _Filter.movies;

    if (movieList.isEmpty && seriesList.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (showMovies && movieList.isNotEmpty) ...[
          _sectionTitle('Movies'),
          _buildGrid(movieList, isMovie: true),
          const SizedBox(height: 24),
        ],
        if (showSeries && seriesList.isNotEmpty) ...[
          _sectionTitle('TV Shows'),
          _buildGrid(seriesList, isMovie: false),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    final isOnline = ref.watch(isOnlineProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_outlined, size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No downloaded media yet',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
          ),
          if (isOnline) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go(Destinations.home),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Browse Library'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGrid(List<DownloadedItem> items, {required bool isMovie}) {
    return LayoutBuilder(builder: (context, constraints) {
      const cardWidth = 130.0;
      final crossAxisCount = (constraints.maxWidth / cardWidth).floor().clamp(2, 8);

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 2 / 3.4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _DownloadedCard(
            item: item,
            onTap: () {
              if (isMovie) {
                _playOffline(item);
              } else {
                context.push(Destinations.downloadedSeries(item.itemId));
              }
            },
            onLongPress: () => _showDeleteDialog(item),
          );
        },
      );
    });
  }

  Future<void> _playOffline(DownloadedItem item) async {
    await launchOfflinePlayback(context, item);
  }

  void _showDeleteDialog(DownloadedItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Download'),
        content: Text('Remove "${item.name}" and its files?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteItem(item);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(DownloadedItem item) async {
    final repo = GetIt.instance<OfflineRepository>();
    final imageDir = await GetIt.instance<StoragePathService>().getImageCacheDir();

    if (item.localFilePath != null) {
      final file = File(item.localFilePath!);
      if (await file.exists()) await file.delete();
    }

    final itemImageDir = Directory('${imageDir.path}/${item.itemId}');
    if (await itemImageDir.exists()) {
      await itemImageDir.delete(recursive: true);
    }

    if (item.type == 'Series') {
      await repo.deleteSeriesItems(item.itemId, item.serverId);
    } else if (item.type == 'Season') {
      await repo.deleteSeasonItems(item.itemId, item.serverId);
    } else {
      await repo.deleteItem(item.itemId, item.serverId);
    }
  }

  String _filterLabel(_Filter f) => switch (f) {
        _Filter.all => 'All',
        _Filter.movies => 'Movies',
        _Filter.tvShows => 'TV Shows',
      };

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _DownloadedCard extends StatelessWidget {
  final DownloadedItem item;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _DownloadedCard({
    required this.item,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: OfflineImage(
                localPath: item.posterPath,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
