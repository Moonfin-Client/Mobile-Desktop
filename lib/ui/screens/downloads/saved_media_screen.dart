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
import '../../../l10n/app_localizations.dart';
import '../../../playback/offline_playback_launcher.dart';
import '../../navigation/destinations.dart';
import '../../widgets/offline_image.dart';
import '../../widgets/sync_indicator.dart';

class SavedMediaScreen extends ConsumerStatefulWidget {
  const SavedMediaScreen({super.key});

  @override
  ConsumerState<SavedMediaScreen> createState() => _SavedMediaScreenState();
}

enum _Filter { all, movies, tvShows, music, books }

class _SavedMediaScreenState extends ConsumerState<SavedMediaScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final movies = ref.watch(downloadedMoviesProvider);
    final series = ref.watch(downloadedSeriesProvider);
    final audio = ref.watch(downloadedAudioProvider);
    final audioBooks = ref.watch(downloadedAudioBooksProvider);
    final books = ref.watch(downloadedBooksProvider);
    final storage = ref.watch(storageUsedProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(storage),
            _buildFilterChips(),
            Expanded(child: _buildContent(movies, series, audio, audioBooks, books)),
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
          Text(
            AppLocalizations.of(context).savedMedia,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const SyncIndicator(),
          const SizedBox(width: 8),
          storage.when(
            data: (bytes) => Text(
              _formatBytes(bytes),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white.withValues(alpha: 0.6), size: 20),
            onPressed: () => context.push(Destinations.storageManagement),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
      ),
    );
  }

  Widget _buildContent(
    AsyncValue<List<DownloadedItem>> movies,
    AsyncValue<List<DownloadedItem>> series,
    AsyncValue<List<DownloadedItem>> audio,
    AsyncValue<List<DownloadedItem>> audioBooks,
    AsyncValue<List<DownloadedItem>> books,
  ) {
    final movieList = movies.valueOrNull ?? [];
    final seriesList = series.valueOrNull ?? [];
    final audioList = audio.valueOrNull ?? [];
    final audioBookList = audioBooks.valueOrNull ?? [];
    final bookList = books.valueOrNull ?? [];
    final musicAlbums = _groupMusicAlbums(audioList);

    final showMovies = _filter == _Filter.all || _filter == _Filter.movies;
    final showSeries = _filter == _Filter.all || _filter == _Filter.tvShows;
    final showMusic = _filter == _Filter.all || _filter == _Filter.music;
    final showBooks = _filter == _Filter.all || _filter == _Filter.books;

    final hasAnything = movieList.isNotEmpty || seriesList.isNotEmpty ||
        audioList.isNotEmpty || audioBookList.isNotEmpty || bookList.isNotEmpty;

    if (!hasAnything) {
      return _buildEmptyState(hasSavedMedia: false);
    }

    final hasVisibleItems =
        (showMovies && movieList.isNotEmpty) ||
        (showSeries && seriesList.isNotEmpty) ||
        (showMusic && (musicAlbums.isNotEmpty || audioBookList.isNotEmpty)) ||
        (showBooks && bookList.isNotEmpty);

    if (!hasVisibleItems) {
      return _buildEmptyState(hasSavedMedia: true);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (showMovies && movieList.isNotEmpty) ...[
          _sectionTitle(AppLocalizations.of(context).movies),
          _buildGrid(movieList, onTap: (item) => _playOffline(item)),
          const SizedBox(height: 24),
        ],
        if (showSeries && seriesList.isNotEmpty) ...[
          _sectionTitle(AppLocalizations.of(context).tvShows),
          _buildGrid(seriesList, onTap: (item) => context.push(Destinations.downloadedSeries(item.itemId))),
          const SizedBox(height: 24),
        ],
        if (showMusic && musicAlbums.isNotEmpty) ...[
          _sectionTitle(AppLocalizations.of(context).musicAlbums),
          _buildAlbumGrid(musicAlbums),
          const SizedBox(height: 24),
        ],
        if (showMusic && audioBookList.isNotEmpty) ...[
          _sectionTitle(AppLocalizations.of(context).audiobooks),
          _buildGrid(audioBookList, onTap: (item) => _playOffline(item)),
          const SizedBox(height: 24),
        ],
        if (showBooks && bookList.isNotEmpty) ...[
          _sectionTitle(AppLocalizations.of(context).books),
          _buildGrid(bookList, onTap: (item) => context.push(Destinations.book(item.itemId, serverId: item.serverId))),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildEmptyState({required bool hasSavedMedia}) {
    final isOnline = ref.watch(isOnlineProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_outlined, size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            hasSavedMedia ? AppLocalizations.of(context).noMediaInFilter : AppLocalizations.of(context).noDownloadedMediaYet,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
          ),
          if (isOnline) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go(Destinations.home),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
              child: Text(AppLocalizations.of(context).browseLibrary),
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

  Widget _buildGrid(List<DownloadedItem> items, {required ValueChanged<DownloadedItem> onTap}) {
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
            onTap: () => onTap(item),
            onLongPress: () => _showDeleteDialog(item),
          );
        },
      );
    });
  }

  Widget _buildAlbumGrid(List<_MusicAlbumGroup> albums) {
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
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return _DownloadedCard(
            item: album.representative,
            title: album.albumName,
            subtitle: AppLocalizations.of(context).tracksCount(album.trackCount),
            onTap: () => context.push(
              Destinations.downloadedAlbum(album.albumId, albumName: album.albumName),
            ),
          );
        },
      );
    });
  }

  List<_MusicAlbumGroup> _groupMusicAlbums(List<DownloadedItem> tracks) {
    final groups = <String, List<DownloadedItem>>{};

    for (final track in tracks) {
      final albumId = track.parsedMetadata['AlbumId'] as String? ?? 'track:${track.itemId}';
      groups.putIfAbsent(albumId, () => []).add(track);
    }

    final albums = groups.entries.map((entry) {
      final items = entry.value;
      items.sort((a, b) {
        final aDisc = a.parentIndexNumber ?? 0;
        final bDisc = b.parentIndexNumber ?? 0;
        if (aDisc != bDisc) return aDisc.compareTo(bDisc);

        final aTrack = a.indexNumber ?? 0;
        final bTrack = b.indexNumber ?? 0;
        if (aTrack != bTrack) return aTrack.compareTo(bTrack);

        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      final first = items.first;
      final albumName = (first.parsedMetadata['Album'] as String?)?.trim();

      return _MusicAlbumGroup(
        albumId: entry.key,
        albumName: albumName == null || albumName.isEmpty ? first.name : albumName,
        representative: first,
        trackCount: items.length,
      );
    }).toList()
      ..sort((a, b) => a.albumName.toLowerCase().compareTo(b.albumName.toLowerCase()));

    return albums;
  }

  Future<void> _playOffline(DownloadedItem item) async {
    await launchOfflinePlayback(context, item);
  }

  void _showDeleteDialog(DownloadedItem item) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteDownload),
        content: Text(l10n.removeItemAndFiles(item.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteItem(item);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.redAccent)),
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
      await repo.deleteSeriesItems(item.itemId);
    } else if (item.type == 'Season') {
      await repo.deleteSeasonItems(item.itemId);
    } else {
      await repo.deleteItem(item.itemId);
    }
  }

  String _filterLabel(_Filter f) => switch (f) {
        _Filter.all => AppLocalizations.of(context).all,
        _Filter.movies => AppLocalizations.of(context).movies,
        _Filter.tvShows => AppLocalizations.of(context).tvShows,
        _Filter.music => AppLocalizations.of(context).music,
        _Filter.books => AppLocalizations.of(context).books,
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
  final String? title;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? subtitle;

  const _DownloadedCard({
    required this.item,
    this.title,
    required this.onTap,
    this.onLongPress,
    this.subtitle,
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
            title ?? item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
        ],
      ),
    );
  }
}

class _MusicAlbumGroup {
  final String albumId;
  final String albumName;
  final DownloadedItem representative;
  final int trackCount;

  const _MusicAlbumGroup({
    required this.albumId,
    required this.albumName,
    required this.representative,
    required this.trackCount,
  });
}
