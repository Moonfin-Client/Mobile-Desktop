import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:playback_core/playback_core.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/repositories/item_mutation_repository.dart';
import '../../../data/repositories/mdblist_repository.dart';
import '../../../data/services/background_service.dart';
import '../../../data/services/download_service.dart';
import '../../../data/models/download_quality.dart';
import '../../../data/database/offline_database.dart';
import '../../../data/models/lyrics.dart';
import '../../../data/repositories/offline_repository.dart';
import '../../../data/services/media_server_client_factory.dart';
import '../../../data/services/book_reader_service.dart';
import '../../../data/services/theme_music_service.dart';
import '../../../data/viewmodels/item_detail_view_model.dart';
import '../../../preference/user_preferences.dart';
import '../../../ui/mixins/focus_state_mixin.dart';
import '../../../auth/repositories/user_repository.dart';
import '../../navigation/destinations.dart';
import '../../widgets/add_to_playlist_dialog.dart';
import '../../widgets/logo_view.dart';
import '../../widgets/media_card.dart';
import '../../widgets/navigation_layout.dart';
import '../../widgets/horizontal_scroll_section.dart';
import '../../widgets/rating_display.dart';
import '../../widgets/track_action_dialog.dart';
import '../../widgets/track_selector_dialog.dart';
import '../../widgets/remote_play_to_session_dialog.dart';
import '../../../playback/offline_playback_launcher.dart';
import '../../../util/audio_labels.dart';
import '../../../util/download_utils.dart';
import '../../../util/platform_detection.dart';

const _textShadows = [Shadow(blurRadius: 4, color: Colors.black54)];
const _kCompactBreakpoint = 600.0;

bool _isCompact(BuildContext context) =>
    PlatformDetection.isMobile ||
    MediaQuery.sizeOf(context).width < _kCompactBreakpoint;

bool _useDesktopDetailLayout(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final isLandscape = size.width > size.height;
  return !(_isCompact(context)) ||
      (PlatformDetection.isMobile && isLandscape && size.width >= 700);
}

Future<bool> _showDeleteConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF171717),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
  );

  return confirmed == true;
}

class ItemDetailScreen extends StatefulWidget {
  final String itemId;
  final String? serverId;

  const ItemDetailScreen({super.key, required this.itemId, this.serverId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen>
  with WidgetsBindingObserver {
  late final ItemDetailViewModel _viewModel;
  final _backgroundService = GetIt.instance<BackgroundService>();
  final _themeMusicService = GetIt.instance<ThemeMusicService>();
  final _prefs = GetIt.instance<UserPreferences>();
  RouteInformationProvider? _routeInformationProvider;
  bool _isDetailRouteActive = true;
  String? _backdropUrl;
  bool _themeMusicStarted = false;
  String? _selectedMediaSourceId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final factory = GetIt.instance<MediaServerClientFactory>();
    final client =
        widget.serverId != null
            ? factory.getClientIfExists(widget.serverId!) ??
                GetIt.instance<MediaServerClient>()
            : GetIt.instance<MediaServerClient>();
    _viewModel = ItemDetailViewModel(
      itemId: widget.itemId,
      serverId: widget.serverId,
      client: client,
      mutations: GetIt.instance<ItemMutationRepository>(),
      mdbListRepository: GetIt.instance<MdbListRepository>(),
    );
    _viewModel.addListener(_onChanged);
    _prefs.addListener(_onPrefsChanged);
    _viewModel.load();

    _backdropUrl = _backgroundService.currentUrl;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = GoRouter.of(context).routeInformationProvider;
    if (!identical(provider, _routeInformationProvider)) {
      _routeInformationProvider?.removeListener(_onRouteChanged);
      _routeInformationProvider = provider;
      _routeInformationProvider?.addListener(_onRouteChanged);
      _onRouteChanged();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _themeMusicService.fadeOutAndStop();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _resumeThemeMusicIfEligible();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _routeInformationProvider?.removeListener(_onRouteChanged);
    _themeMusicService.fadeOutAndStop();
    _backgroundService.clearBackgrounds();
    _viewModel.removeListener(_onChanged);
    _prefs.removeListener(_onPrefsChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    final item = _viewModel.item;
    if (item != null) {
      _backgroundService.setBackground(item, context: BlurContext.details);
      _backdropUrl = _backgroundService.currentUrl;
      if (!_themeMusicStarted) {
        _themeMusicStarted = true;
        _themeMusicService.playForItem(item);
      }
    }
  }

  void _onPrefsChanged() {
    if (mounted) setState(() {});
  }

  void _onRouteChanged() {
    final path = _routeInformationProvider?.value.uri.path ?? '';
    final isDetailRoute = path == '/item/${widget.itemId}';
    if (_isDetailRouteActive == isDetailRoute) {
      return;
    }

    _isDetailRouteActive = isDetailRoute;
    if (!_isDetailRouteActive) {
      _themeMusicService.fadeOutAndStop();
      return;
    }

    _resumeThemeMusicIfEligible();
  }

  void _resumeThemeMusicIfEligible() {
    final item = _viewModel.item;
    if (!_isDetailRouteActive || item == null) {
      return;
    }

    _themeMusicStarted = true;
    _themeMusicService.playForItem(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NavigationLayout(showBackButton: true, child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    return switch (_viewModel.state) {
      ItemDetailState.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      ItemDetailState.error => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              _viewModel.errorMessage ?? 'Failed to load',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _viewModel.load,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      ItemDetailState.ready => _DetailContent(
        viewModel: _viewModel,
        prefs: _prefs,
        backdropUrl: _backdropUrl,
        selectedMediaSourceId: _selectedMediaSourceId,
        onSelectedMediaSourceChanged:
            (id) => setState(() => _selectedMediaSourceId = id),
      ),
    };
  }
}

class _DetailContent extends StatelessWidget {
  final ItemDetailViewModel viewModel;
  final UserPreferences prefs;
  final String? backdropUrl;
  final String? selectedMediaSourceId;
  final ValueChanged<String?> onSelectedMediaSourceChanged;

  const _DetailContent({
    required this.viewModel,
    required this.prefs,
    this.backdropUrl,
    this.selectedMediaSourceId,
    required this.onSelectedMediaSourceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final item = viewModel.item!;
    final selectedMediaSource = _selectedMediaSourceForItem(item, selectedMediaSourceId);
    final blurAmount =
        prefs.get(UserPreferences.detailsBackgroundBlurAmount).toDouble();
    final backdropEnabled = prefs.get(UserPreferences.backdropEnabled);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (backdropEnabled)
          _Backdrop(url: backdropUrl, blurAmount: blurAmount),
        const _GradientScrim(),
        CustomScrollView(
          slivers: [
            if (item.type != 'Person' &&
                item.type != 'MusicArtist' &&
                item.type != 'MusicAlbum' &&
                item.type != 'Playlist')
              SliverToBoxAdapter(
                child: _HeaderSection(
                  viewModel: viewModel,
                  prefs: prefs,
                  selectedMediaSource: selectedMediaSource,
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: _isCompact(context) ? 16 : 48,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  _buildContentForType(context, item),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildContentForType(BuildContext context, AggregatedItem item) {
    return switch (item.type) {
      'Series' => _buildSeriesContent(item),
      'Season' => _buildSeasonContent(item),
      'Episode' => _buildEpisodeContent(context, item),
      'Person' => _buildPersonContent(item),
      'MusicArtist' => _buildArtistContent(item),
      'MusicAlbum' || 'Playlist' => _buildAlbumContent(context, item),
      'BoxSet' => _buildBoxSetContent(item),
      'Photo' => _buildPhotoContent(item),
      _ => _buildMovieContent(context, item),
    };
  }

  List<Widget> _buildPhotoContent(AggregatedItem item) {
    final raw = item.rawData;
    final width = raw['Width'] as int?;
    final height = raw['Height'] as int?;
    final cameraMake = raw['CameraMake'] as String?;
    final cameraModel = raw['CameraModel'] as String?;
    final software = raw['Software'] as String?;
    final dateTaken = raw['DateCreated'] as String?;

    final exifEntries = <String>[
      if (width != null && height != null) '$width×$height',
      if (cameraMake != null) cameraMake,
      if (cameraModel != null) cameraModel,
      if (software != null) software,
      if (dateTaken != null) dateTaken.split('T').first,
    ];

    return [
      _ActionButtons(
        viewModel: viewModel,
        selectedMediaSourceId: selectedMediaSourceId,
        onSelectedMediaSourceChanged: onSelectedMediaSourceChanged,
      ),
      if (exifEntries.isNotEmpty) ...[
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children:
                exifEntries
                    .map(
                      (e) => Chip(
                        label: Text(
                          e,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
      const SizedBox(height: 48),
    ];
  }

  List<Widget> _buildMovieContent(BuildContext context, AggregatedItem item) {
    return [
      _ActionButtons(
        viewModel: viewModel,
        selectedMediaSourceId: selectedMediaSourceId,
        onSelectedMediaSourceChanged: onSelectedMediaSourceChanged,
      ),
      if (_hasMetadata(item)) ...[
        const SizedBox(height: 24),
        _MetadataSection(viewModel: viewModel),
      ],
      ..._buildChapterAndFeatureSections(
        context,
        item,
        selectedMediaSourceId: selectedMediaSourceId,
      ),
      if (viewModel.actors.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'Cast & Crew',
          builder: (_, ctrl) => _CastRow(
            people: viewModel.actors,
            imageApi: viewModel.imageApi,
            serverId: viewModel.item?.serverId,
            scrollController: ctrl,
          ),
        ),
      ],
      if (viewModel.parentCollectionItems.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: viewModel.parentCollectionName ?? 'Collection',
          builder: (_, ctrl) => _SimilarRow(
            items: viewModel.parentCollectionItems,
            imageApi: viewModel.imageApi,
            prefs: prefs,
            scrollController: ctrl,
          ),
        ),
      ],
      if (viewModel.similar.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'More Like This',
          builder: (_, ctrl) => _SimilarRow(
            items: viewModel.similar,
            imageApi: viewModel.imageApi,
            prefs: prefs,
            scrollController: ctrl,
          ),
        ),
      ],
      const SizedBox(height: 48),
    ];
  }

  List<Widget> _buildSeriesContent(AggregatedItem item) {
    return [
      _ActionButtons(
        viewModel: viewModel,
        selectedMediaSourceId: selectedMediaSourceId,
        onSelectedMediaSourceChanged: onSelectedMediaSourceChanged,
      ),
      if (_hasMetadata(item)) ...[
        const SizedBox(height: 24),
        _MetadataSection(viewModel: viewModel),
      ],
      if (viewModel.nextUp != null) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'Next Up'),
        const SizedBox(height: 12),
        _NextUpCard(episode: viewModel.nextUp!, imageApi: viewModel.imageApi),
      ],
      if (viewModel.seasons.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'Seasons',
          builder: (_, ctrl) => _SeasonsRow(
            seasons: viewModel.seasons,
            imageApi: viewModel.imageApi,
            prefs: prefs,
            scrollController: ctrl,
          ),
        ),
      ],
      if (viewModel.actors.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'Cast & Crew',
          builder: (_, ctrl) => _CastRow(
            people: viewModel.actors,
            imageApi: viewModel.imageApi,
            serverId: viewModel.item?.serverId,
            scrollController: ctrl,
          ),
        ),
      ],
      if (viewModel.similar.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'More Like This',
          builder: (_, ctrl) => _SimilarRow(
            items: viewModel.similar,
            imageApi: viewModel.imageApi,
            prefs: prefs,
            scrollController: ctrl,
          ),
        ),
      ],
      const SizedBox(height: 48),
    ];
  }

  List<Widget> _buildSeasonContent(AggregatedItem item) {
    return [
      _ActionButtons(
        viewModel: viewModel,
        selectedMediaSourceId: selectedMediaSourceId,
        onSelectedMediaSourceChanged: onSelectedMediaSourceChanged,
      ),
      if (viewModel.episodes.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'Episodes'),
        const SizedBox(height: 12),
        ...viewModel.episodes.map(
          (ep) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _EpisodeCard(episode: ep, imageApi: viewModel.imageApi),
          ),
        ),
      ],
      const SizedBox(height: 48),
    ];
  }

  List<Widget> _buildEpisodeContent(BuildContext context, AggregatedItem item) {
    return [
      _ActionButtons(
        viewModel: viewModel,
        selectedMediaSourceId: selectedMediaSourceId,
        onSelectedMediaSourceChanged: onSelectedMediaSourceChanged,
      ),
      if (_hasMetadata(item)) ...[
        const SizedBox(height: 24),
        _MetadataSection(viewModel: viewModel),
      ],
      ..._buildChapterAndFeatureSections(
        context,
        item,
        selectedMediaSourceId: selectedMediaSourceId,
      ),
      if (viewModel.episodes.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'Episodes',
          builder: (_, ctrl) => _EpisodesRow(
            episodes: viewModel.episodes,
            currentEpisodeId: item.id,
            imageApi: viewModel.imageApi,
            scrollController: ctrl,
          ),
        ),
      ],
      if (viewModel.actors.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'Cast & Crew',
          builder: (_, ctrl) => _CastRow(
            people: viewModel.actors,
            imageApi: viewModel.imageApi,
            serverId: viewModel.item?.serverId,
            scrollController: ctrl,
          ),
        ),
      ],
      if (viewModel.similar.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'More Like This',
          builder: (_, ctrl) => _SimilarRow(
            items: viewModel.similar,
            imageApi: viewModel.imageApi,
            prefs: prefs,
            scrollController: ctrl,
          ),
        ),
      ],
      const SizedBox(height: 48),
    ];
  }

  void _playFromChapter(
    BuildContext context,
    AggregatedItem item,
    Duration startPosition,
    String? mediaSourceId,
  ) {
    final manager = GetIt.instance<PlaybackManager>();
    manager.playItems(
      [item],
      startPosition: startPosition,
      mediaSourceId: mediaSourceId,
    );
    context.push(Destinations.videoPlayer);
  }

  List<Widget> _buildChapterAndFeatureSections(
    BuildContext context,
    AggregatedItem item,
    {String? selectedMediaSourceId,}
  ) {
    return [
      if (item.chapters.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'Chapters',
          builder: (_, ctrl) => _ChaptersRow(
            item: item,
            imageApi: viewModel.imageApi,
            onPlayFromChapter:
                (position) => _playFromChapter(
                  context,
                  item,
                  position,
                  selectedMediaSourceId,
                ),
            scrollController: ctrl,
          ),
        ),
      ],
      if (viewModel.features.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'Features',
          builder: (_, ctrl) => _FeaturesRow(
            items: viewModel.features,
            imageApi: viewModel.imageApi,
            prefs: prefs,
            scrollController: ctrl,
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildPersonContent(AggregatedItem item) {
    final movies = viewModel.filmographyMovies;
    final series = viewModel.filmographySeries;

    return [
      _PersonHeader(item: item, imageApi: viewModel.imageApi),
      if (item.overview != null && item.overview!.isNotEmpty) ...[
        const SizedBox(height: 24),
        _ExpandableBiography(text: item.overview!),
      ],
      if (movies.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'Movies',
          builder: (_, ctrl) => _FilmographyRow(
            items: movies,
            imageApi: viewModel.imageApi,
            prefs: prefs,
            scrollController: ctrl,
          ),
        ),
      ],
      if (series.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'Series',
          builder: (_, ctrl) => _FilmographyRow(
            items: series,
            imageApi: viewModel.imageApi,
            prefs: prefs,
            scrollController: ctrl,
          ),
        ),
      ],
      const SizedBox(height: 48),
    ];
  }

  List<Widget> _buildArtistContent(AggregatedItem item) {
    return [
      _ArtistHeader(item: item, imageApi: viewModel.imageApi),
      if (item.overview != null && item.overview!.isNotEmpty) ...[
        const SizedBox(height: 24),
        _OverviewText(text: item.overview!),
      ],
      if (viewModel.albums.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'Discography',
          builder: (_, ctrl) => _AlbumsRow(
            albums: viewModel.albums,
            imageApi: viewModel.imageApi,
            prefs: prefs,
            scrollController: ctrl,
          ),
        ),
      ],
      if (viewModel.similar.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'Similar Artists',
          builder: (_, ctrl) => _SimilarRow(
            items: viewModel.similar,
            imageApi: viewModel.imageApi,
            prefs: prefs,
            scrollController: ctrl,
          ),
        ),
      ],
      const SizedBox(height: 48),
    ];
  }

  List<Widget> _buildAlbumContent(BuildContext context, AggregatedItem item) {
    final isPlaylist = item.type == 'Playlist';
    final canManagePlaylistTracks =
        isPlaylist && viewModel.canManagePlaylistTracks;
    final canDeleteItem = item.canDelete;
    final canDownloadAll =
      _canUserDownload() &&
      (item.type == 'MusicAlbum' ||
      (item.type == 'Playlist' &&
        viewModel.tracks.isNotEmpty &&
        viewModel.tracks.every(_isAudioItem)));
    final canDeleteDownloaded = item.type == 'MusicAlbum';
    return [
      _AlbumHeader(
        item: item,
        imageApi: viewModel.imageApi,
        onRenameRequested:
            isPlaylist ? () => _showRenamePlaylistDialog(context, item) : null,
      ),
      const SizedBox(height: 16),
      _AlbumActions(
        item: item,
        tracks: viewModel.tracks,
        showAddToPlaylist: !isPlaylist,
        onDownloadAll:
          canDownloadAll
            ? () => _downloadTrackList(context, item.name, viewModel.tracks)
            : null,
        onDeleteDownloaded:
          canDeleteDownloaded
            ? () => _confirmDeleteDownloadedAlbum(context, item.name)
            : null,
        onDeletePlaylist:
            canDeleteItem ? () => _confirmDeleteServerItem(context, item) : null,
      ),
      if (viewModel.tracks.isNotEmpty) ...[
        const SizedBox(height: 24),
        _TrackList(
          tracks: viewModel.tracks,
          reorderable: canManagePlaylistTracks,
          onPlayTrack: (index) {
            final manager = GetIt.instance<PlaybackManager>();
            manager.playItems(viewModel.tracks, startIndex: index);
            context.push(Destinations.audioPlayer);
          },
          onReorder:
              canManagePlaylistTracks
                  ? (oldIndex, newIndex) =>
                      viewModel.reorderPlaylistTrack(oldIndex, newIndex)
                  : null,
          onRemoveFromPlaylist:
              canManagePlaylistTracks
                  ? (track) => viewModel.removeTrackFromPlaylist(track)
                  : null,
          onMoveUp:
              canManagePlaylistTracks
                  ? (index) => viewModel.reorderPlaylistTrack(index, index - 1)
                  : null,
          onMoveDown:
              canManagePlaylistTracks
                  ? (index) => viewModel.reorderPlaylistTrack(index, index + 2)
                  : null,
        ),
      ],
      const SizedBox(height: 48),
    ];
  }

  bool _isAudioItem(AggregatedItem item) {
    final mediaType = item.rawData['MediaType'] as String?;
    return item.type == 'Audio' || item.type == 'AudioBook' || mediaType == 'Audio';
  }

  void _downloadTrackList(
    BuildContext context,
    String title,
    List<AggregatedItem> tracks,
  ) {
    if (tracks.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No tracks loaded')));
      return;
    }

    GetIt.instance<DownloadService>().downloadItems(tracks);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $title (${tracks.length} items)...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmDeleteDownloadedAlbum(
    BuildContext context,
    String title,
  ) async {
    final tracks = viewModel.tracks.where(_isAudioItem).toList(growable: false);
    if (tracks.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No tracks loaded')));
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF171717),
            title: const Text(
              'Delete Downloaded Album',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Delete downloaded tracks for "$title"?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (ok != true || !context.mounted) return;

    final success = await GetIt.instance<DownloadService>().deleteDownloadedItems(
      tracks,
    );
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Downloaded tracks deleted'
              : 'Some downloaded tracks could not be deleted',
        ),
      ),
    );
  }

  Future<void> _confirmDeleteServerItem(
    BuildContext context,
    AggregatedItem item,
  ) async {
    final isPlaylist = item.type == 'Playlist';
    final confirmed = await _showDeleteConfirmationDialog(
      context,
      title: isPlaylist ? 'Delete Playlist' : 'Delete Item',
      message: isPlaylist
          ? 'Delete this playlist from the server?'
          : 'Delete this item from the server?',
    );
    if (!confirmed) return;

    final success = await viewModel.deleteItem();
    if (!context.mounted) return;
    if (success) {
      context.pop(true);
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          isPlaylist ? 'Failed to delete playlist' : 'Failed to delete item',
        ),
      ),
    );
  }

  Future<void> _showRenamePlaylistDialog(
    BuildContext context,
    AggregatedItem item,
  ) async {
    final controller = TextEditingController(text: item.name);
    final newName = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF171717),
            title: const Text(
              'Rename Playlist',
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Playlist name'),
              onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
    );
    controller.dispose();
    if (newName == null || newName.isEmpty || newName == item.name) return;
    await viewModel.renamePlaylist(newName);
  }

  List<Widget> _buildBoxSetContent(AggregatedItem item) {
    final movies =
        viewModel.collectionItems.where((i) => i.type == 'Movie').toList();
    final series =
        viewModel.collectionItems.where((i) => i.type == 'Series').toList();
    final other =
        viewModel.collectionItems
            .where((i) => i.type != 'Movie' && i.type != 'Series')
            .toList();

    return [
      if (_hasMetadata(item)) ...[
        const SizedBox(height: 24),
        _MetadataSection(viewModel: viewModel),
      ],
      if (movies.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'Movies',
          builder: (_, ctrl) => _SimilarRow(
            items: movies,
            imageApi: viewModel.imageApi,
            prefs: prefs,
            scrollController: ctrl,
          ),
        ),
      ],
      if (series.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'Series',
          builder: (_, ctrl) => _SimilarRow(
            items: series,
            imageApi: viewModel.imageApi,
            prefs: prefs,
            scrollController: ctrl,
          ),
        ),
      ],
      if (other.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'Other',
          builder: (_, ctrl) => _SimilarRow(
            items: other,
            imageApi: viewModel.imageApi,
            prefs: prefs,
            scrollController: ctrl,
          ),
        ),
      ],
      if (viewModel.actors.isNotEmpty) ...[
        const SizedBox(height: 32),
        HorizontalScrollSection(
          title: 'Cast & Crew',
          builder: (_, ctrl) => _CastRow(
            people: viewModel.actors,
            imageApi: viewModel.imageApi,
            serverId: viewModel.item?.serverId,
            scrollController: ctrl,
          ),
        ),
      ],
      const SizedBox(height: 48),
    ];
  }

  bool _hasMetadata(AggregatedItem item) {
    return viewModel.directors.isNotEmpty ||
        viewModel.writers.isNotEmpty ||
        item.studios.isNotEmpty;
  }
}

class _Backdrop extends StatelessWidget {
  final String? url;
  final double blurAmount;

  const _Backdrop({this.url, required this.blurAmount});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: BackgroundService.transitionDuration,
      child:
          url != null
              ? SizedBox.expand(
                key: ValueKey(url),
                child: _blurredImage(url!, blurAmount),
              )
              : const SizedBox.expand(key: ValueKey('empty')),
    );
  }

  Widget _blurredImage(String imageUrl, double blur) {
    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
    if (blur <= 0) return image;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: blur,
        sigmaY: blur,
        tileMode: TileMode.decal,
      ),
      child: image,
    );
  }
}

class _GradientScrim extends StatelessWidget {
  const _GradientScrim();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCC000000), Color(0x66000000), Color(0xCC000000)],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final ItemDetailViewModel viewModel;
  final UserPreferences prefs;
  final Map<String, dynamic>? selectedMediaSource;

  const _HeaderSection({
    required this.viewModel,
    required this.prefs,
    this.selectedMediaSource,
  });

  @override
  Widget build(BuildContext context) {
    final item = viewModel.item!;
    final imageApi = viewModel.imageApi;
    final isEpisode = item.type == 'Episode';
    final useDesktopLayout = _useDesktopDetailLayout(context);
    final isMobile = !useDesktopLayout;
    final mediaType = item.rawData['MediaType'] as String?;
    final isMusicItem = item.type == 'Audio' || mediaType == 'Audio';
    final showLyrics = useDesktopLayout && isMusicItem && viewModel.lyrics.isNotEmpty;

    final infoColumn = Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isEpisode && item.seriesName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Wrap(
              alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  item.seriesName!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    shadows: _textShadows,
                    fontSize: isMobile ? 14 : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.parentIndexNumber != null && item.indexNumber != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'S${item.parentIndexNumber}E${item.indexNumber}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (!isEpisode && item.logoImageTag != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child:
                isMobile
                    ? Center(
                      child: LogoView(
                        imageUrl: imageApi.getLogoImageUrl(
                          item.id,
                          tag: item.logoImageTag,
                        ),
                        maxHeight: 56,
                        maxWidth: 240,
                      ),
                    )
                    : LogoView(
                      imageUrl: imageApi.getLogoImageUrl(
                        item.id,
                        tag: item.logoImageTag,
                      ),
                      maxHeight: 80,
                      maxWidth: 350,
                    ),
          )
        else
          Text(
            item.name,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: _textShadows,
              fontSize: isMobile ? 24 : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: isMobile ? TextAlign.center : null,
          ),
        const SizedBox(height: 8),
        _MetadataRow(item: item, selectedMediaSource: selectedMediaSource),
        if (viewModel.ratings.isNotEmpty ||
            item.communityRating != null ||
            item.criticRating != null) ...[
          const SizedBox(height: 8),
          RatingsRow(
            ratings: viewModel.ratings,
            communityRating: item.communityRating,
            criticRating: item.criticRating,
            enableAdditionalRatings: prefs.get(
              UserPreferences.enableAdditionalRatings,
            ),
            enabledRatings: prefs.get(UserPreferences.enabledRatings),
            blockedRatings: prefs.get(UserPreferences.blockedRatings),
            showLabels: prefs.get(UserPreferences.showRatingLabels),
            showBadges: prefs.get(UserPreferences.showRatingBadges),
          ),
        ],
        if (item.tagline != null) ...[
          const SizedBox(height: 6),
          Text(
            item.tagline!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
              shadows: _textShadows,
              fontSize: isMobile ? 13 : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: isMobile ? TextAlign.center : null,
          ),
        ],
        if (item.overview != null && item.overview!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            item.overview!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              shadows: _textShadows,
              height: 1.4,
              fontSize: isMobile ? 13 : null,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: isMobile ? TextAlign.center : null,
          ),
        ],
      ],
    );

    final posterWidget =
        isEpisode
            ? _EpisodeThumbnail(item: item, imageApi: imageApi)
            : _PosterImage(item: item, imageApi: imageApi);

    final safeTop = MediaQuery.of(context).padding.top;

    if (isMobile) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16, safeTop + 60, 16, 12),
        child: Column(
          children: [posterWidget, const SizedBox(height: 16), infoColumn],
        ),
      );
    }

    if (showLyrics) {
      return Padding(
        padding: EdgeInsets.fromLTRB(48, safeTop + 80, 48, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            posterWidget,
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  infoColumn,
                  const SizedBox(height: 16),
                  _LyricsPanel(lyrics: viewModel.lyrics),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(48, safeTop + 80, 48, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: infoColumn),
          const SizedBox(width: 32),
          posterWidget,
        ],
      ),
    );
  }
}

class _LyricsPanel extends StatelessWidget {
  final LyricsData lyrics;

  const _LyricsPanel({required this.lyrics});

  @override
  Widget build(BuildContext context) {
    final lines =
        lyrics.lines
            .map((line) => line.text.trim())
            .where((line) => line.isNotEmpty)
            .toList(growable: false);
    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 280),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Text(
            lines.join('\n'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.45,
              shadows: _textShadows,
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadedBadge extends StatefulWidget {
  final String itemId;
  const _DownloadedBadge({required this.itemId});

  @override
  State<_DownloadedBadge> createState() => _DownloadedBadgeState();
}

class _DownloadedBadgeState extends State<_DownloadedBadge> {
  bool _downloaded = false;
  DownloadService? _downloadService;

  @override
  void initState() {
    super.initState();
    if (GetIt.instance.isRegistered<DownloadService>()) {
      _downloadService = GetIt.instance<DownloadService>();
      _downloadService!.addListener(_onDownloadChanged);
    }
    _check();
  }

  @override
  void dispose() {
    _downloadService?.removeListener(_onDownloadChanged);
    super.dispose();
  }

  void _onDownloadChanged() => _check();

  Future<void> _check() async {
    final repo = GetIt.instance<OfflineRepository>();
    final available = await repo.isAvailableOffline(
      widget.itemId,
    );
    if (mounted && available != _downloaded) {
      setState(() => _downloaded = available);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_downloaded) return const SizedBox.shrink();
    return Positioned(
      bottom: 8,
      left: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_done, color: Colors.white, size: 12),
            SizedBox(width: 3),
            Text(
              'Downloaded',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                overflow: TextOverflow.clip,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterImage extends StatelessWidget {
  final AggregatedItem item;
  final ImageApi imageApi;

  const _PosterImage({required this.item, required this.imageApi});

  @override
  Widget build(BuildContext context) {
    final isMobile = !_useDesktopDetailLayout(context);
    final w = isMobile ? 120.0 : 165.0;
    final h = isMobile ? 180.0 : 248.0;
    final isBook = _isReadableBookItem(item);

    if (item.primaryImageTag == null) return SizedBox(width: w, height: h);

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageApi.getPrimaryImageUrl(
                item.id,
                maxHeight: isMobile ? 360 : 500,
                tag: item.primaryImageTag,
              ),
              width: w,
              height: h,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => SizedBox(width: w, height: h),
            ),
          ),
          if (item.isFavorite)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFFFF4757),
                  size: 16,
                ),
              ),
            ),
          if (!isBook && item.isPlayed)
            Positioned(
              top: 6,
              right: 6,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFF00A4DC),
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
            ),
          if (!isBook && (item.playedPercentage ?? 0) > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: LinearProgressIndicator(
                  value: item.playedPercentage! / 100.0,
                  minHeight: 4,
                  backgroundColor: Colors.black38,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00A4DC),
                  ),
                ),
              ),
            ),
          _DownloadedBadge(itemId: item.id),
        ],
      ),
    );
  }
}

class _EpisodeThumbnail extends StatelessWidget {
  final AggregatedItem item;
  final ImageApi imageApi;

  const _EpisodeThumbnail({required this.item, required this.imageApi});

  @override
  Widget build(BuildContext context) {
    final isMobile = !_useDesktopDetailLayout(context);
    final w = isMobile ? 200.0 : 280.0;
    final h = isMobile ? 113.0 : 158.0;

    if (item.primaryImageTag == null) return SizedBox(width: w, height: h);

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: imageApi.getPrimaryImageUrl(
                item.id,
                maxWidth: isMobile ? 400 : 560,
                tag: item.primaryImageTag,
              ),
              width: w,
              height: h,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => SizedBox(width: w, height: h),
            ),
          ),
          if (item.isFavorite)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFFFF4757),
                  size: 14,
                ),
              ),
            ),
          if (item.isPlayed)
            Positioned(
              top: 6,
              right: 6,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFF00A4DC),
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(Icons.check, color: Colors.white, size: 10),
                ),
              ),
            ),
          if ((item.playedPercentage ?? 0) > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: LinearProgressIndicator(
                  value: item.playedPercentage! / 100.0,
                  minHeight: 3,
                  backgroundColor: Colors.black38,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00A4DC),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final AggregatedItem item;
  final Map<String, dynamic>? selectedMediaSource;

  const _MetadataRow({required this.item, this.selectedMediaSource});

  @override
  Widget build(BuildContext context) {
    final parts = <Widget>[];
    final theme = Theme.of(context);
    final isBook = _isReadableBookItem(item);

    if (item.productionYear != null) {
      parts.add(_text(theme, item.productionYear.toString()));
    }

    if (item.officialRating != null) {
      parts.add(_badge(theme, item.officialRating!));
    }

    final runtime = _runtimeForItem(item, selectedMediaSource);
    if (!isBook && runtime != null && item.type != 'Series') {
      final h = runtime.inHours;
      final m = runtime.inMinutes.remainder(60);
      parts.add(_text(theme, h > 0 ? '${h}h ${m}m' : '${m}m'));
    }

    if (item.type == 'Series') {
      final count = item.childCount;
      if (count != null) {
        parts.add(_text(theme, count == 1 ? '1 Season' : '$count Seasons'));
      }
      final status = item.status;
      if (status != null) {
        parts.add(_statusBadge(theme, status));
      }
    }

    final use24 = GetIt.instance<UserPreferences>().get(
      UserPreferences.use24HourClock,
    );
    final endsAt = _endsAt(item, runtime, use24Hour: use24);
    if (!isBook && endsAt != null && item.type != 'Series') {
      parts.add(_text(theme, 'Ends at $endsAt'));
    }

    if (item.genres.isNotEmpty) {
      parts.add(_text(theme, item.genres.take(3).join(' \u2022 ')));
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    final separated = <Widget>[];
    for (var i = 0; i < parts.length; i++) {
      separated.add(parts[i]);
      if (i < parts.length - 1) {
        separated.add(
          Text(
            ' \u2022 ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.5),
              shadows: _textShadows,
            ),
          ),
        );
      }
    }

    final streams = _mediaStreamsForItem(item, selectedMediaSource);
    final badges = <String>[];
    final res = _resolutionFromStreams(streams) ?? item.videoResolution;
    if (res != null) badges.add(res);
    final hdr = _hdrFromStreams(streams) ?? item.hdrType;
    if (hdr != null) badges.add(hdr);
    final vcodec = _codecFromStreams(streams, 'Video') ?? item.videoCodec?.toUpperCase();
    if (vcodec != null) badges.add(vcodec);
    final acodec = _audioLabelFromStreams(streams) ??
      audioLabelFromProfileCodec(item.audioProfile, item.audioCodec);
    if (acodec != null) badges.add(acodec);
    final layout = _channelLayoutFromStreams(streams) ?? item.channelLayout;
    if (layout != null) badges.add(layout);

    final compact = !_useDesktopDetailLayout(context);

    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: compact ? WrapAlignment.center : WrapAlignment.start,
          spacing: 2,
          runSpacing: 4,
          children: [
            ...separated,
            if (!compact && badges.isNotEmpty) ...[
              Text(
                ' \u2022 ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                  shadows: _textShadows,
                ),
              ),
              ...badges.map((b) => _techChip(theme, b)),
            ],
          ],
        ),
        if (compact && badges.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: badges.map((b) => _techChip(theme, b)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _text(ThemeData theme, String value) {
    return Text(
      value,
      style: theme.textTheme.bodySmall?.copyWith(
        color: Colors.white.withValues(alpha: 0.9),
        fontWeight: FontWeight.w700,
        shadows: _textShadows,
      ),
    );
  }

  Widget _badge(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.9),
          shadows: _textShadows,
        ),
      ),
    );
  }

  Widget _statusBadge(ThemeData theme, String status) {
    final isEnded = status.toLowerCase() == 'ended';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isEnded ? const Color(0xFFB71C1C) : const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isEnded ? 'Ended' : 'Continuing',
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _techChip(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.8),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionButtons extends StatefulWidget {
  final ItemDetailViewModel viewModel;
  final String? selectedMediaSourceId;
  final ValueChanged<String?> onSelectedMediaSourceChanged;

  const _ActionButtons({
    required this.viewModel,
    this.selectedMediaSourceId,
    required this.onSelectedMediaSourceChanged,
  });

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  int? _selectedAudioIndex;
  int? _selectedSubtitleIndex;
  bool _expanded = false;
  DownloadedItem? _offlineRow;
  List<DownloadedItem>? _offlineQueue;
  DownloadService? _downloadService;

  ItemDetailViewModel get viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    if (GetIt.instance.isRegistered<DownloadService>()) {
      _downloadService = GetIt.instance<DownloadService>();
      _downloadService!.addListener(_onDownloadChanged);
    }
    _checkOffline();
  }

  @override
  void dispose() {
    _downloadService?.removeListener(_onDownloadChanged);
    super.dispose();
  }

  void _onDownloadChanged() => _checkOffline();

  int _calculateMaxVisibleButtons(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = !_useDesktopDetailLayout(context);
    final buttonWidth = compact ? 80.0 : 96.0;
    const spacing = 8.0;
    const horizontalPadding = 64.0;
    
    final availableWidth = screenWidth - horizontalPadding;
    final maxButtons = ((availableWidth + spacing) / (buttonWidth + spacing)).floor();
    
    return maxButtons > 2 ? maxButtons : 2;
  }

  Future<void> _checkOffline() async {
    final item = viewModel.item;
    if (item == null || !_isDownloadable(item.type)) return;
    final repo = GetIt.instance<OfflineRepository>();
    final type = item.type;

    if (type == 'Season' || type == 'Series') {
      final episodes =
          type == 'Season'
              ? await repo.getSeasonEpisodes(item.id)
              : await repo.getSeriesEpisodes(item.id);
      final playable =
          episodes
              .where((e) => e.downloadStatus == 2 && e.localFilePath != null)
              .toList();
      if (mounted) {
        setState(() {
          _offlineRow = playable.isNotEmpty ? playable.first : null;
          _offlineQueue = playable.isNotEmpty ? playable : null;
        });
      }
    } else {
      final row = await repo.getItem(item.id);
      if (mounted) {
        setState(() {
          _offlineRow = (row != null && row.downloadStatus == 2) ? row : null;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant _ActionButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMediaSourceId != widget.selectedMediaSourceId) {
      _selectedAudioIndex = null;
      _selectedSubtitleIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = viewModel.item!;
    final isPhoto = item.type == 'Photo';
    final isBook = _isReadableBookItem(item);
    final hasProgress =
        (item.playedPercentage ?? 0) > 0 ||
        (item.playbackPosition?.inMilliseconds ?? 0) > 0;
    final selectedSource = _selectedMediaSourceForItem(item, widget.selectedMediaSourceId);
    final mediaStreams = _mediaStreamsForItem(item, selectedSource);
    final audioStreams = mediaStreams.where((s) => s['Type'] == 'Audio').toList();
    final subtitleStreams = mediaStreams.where((s) => s['Type'] == 'Subtitle').toList();

    final allButtons = <Widget>[
      _DetailActionButton(
        label:
            isPhoto
                ? 'View'
                : isBook
                ? (hasProgress ? 'Resume Reading' : 'Read')
                : hasProgress
                ? 'Resume from ${_formatResumePosition(item.playbackPosition)}'
                : 'Play',
        icon:
            isPhoto
                ? Icons.photo
                : isBook
                ? Icons.menu_book
                : Icons.play_arrow,
        onPressed: () => _play(context, item, resume: !isPhoto && hasProgress),
      ),
      if (hasProgress && !isPhoto)
        _DetailActionButton(
          label: isBook ? 'Start Over' : 'Restart',
          icon: Icons.restart_alt,
          onPressed: () => _play(context, item),
        ),
      if (_offlineRow != null)
        _DetailActionButton(
          label: isBook
              ? 'Read Offline'
              : 'Play Offline',
          icon: isBook ? Icons.menu_book : Icons.offline_pin,
          onPressed: () async {
            if (context.mounted) {
              if (isBook) {
                await context.push(
                  Destinations.book(item.id, serverId: item.serverId),
                );
              } else {
                await launchOfflinePlayback(
                  context,
                  _offlineRow!,
                  episodeQueue: _offlineQueue,
                );
              }
            }
          },
          isActive: true,
          activeColor: const Color(0xFF4CAF50),
        ),
      if (audioStreams.length > 1)
        _DetailActionButton(
          label: 'Audio',
          icon: Icons.audiotrack,
          onPressed: () => _showAudioSelector(context, audioStreams),
        ),
      if (subtitleStreams.isNotEmpty || _canDownloadRemoteSubtitles(item))
        _DetailActionButton(
          label: 'Subtitles',
          icon: Icons.subtitles,
          onPressed:
              () => _showSubtitleSelector(
                context,
                item,
                subtitleStreams,
                audioStreams,
              ),
        ),
      if (item.mediaSources.length > 1)
        _DetailActionButton(
          label: 'Version',
          icon: Icons.video_file,
          onPressed: () => _showVersionSelector(context, item.mediaSources),
          isActive: widget.selectedMediaSourceId != null,
          activeColor: const Color(0xFF00A4DC),
        ),
      if (!isBook)
        _DetailActionButton(
          label: 'Cast',
          icon: Icons.cast,
          onPressed: () => _castToDevice(context, item),
        ),
      if (_hasTrailer(item))
        _DetailActionButton(
          label: 'Trailer',
          icon: Icons.movie_outlined,
          onPressed: () => _playTrailer(context, item),
        ),
      if (!isBook)
        _DetailActionButton(
          label: item.isPlayed ? 'Watched' : 'Unwatched',
          icon: item.isPlayed ? Icons.check_circle : Icons.check_circle_outline,
          onPressed: viewModel.togglePlayed,
          isActive: item.isPlayed,
          activeColor: const Color(0xFF00A4DC),
        ),
      _DetailActionButton(
        label: item.isFavorite ? 'Favorited' : 'Favorite',
        icon: Icons.favorite,
        onPressed: viewModel.toggleFavorite,
        isActive: item.isFavorite,
        activeColor: const Color(0xFFFF4757),
      ),
      if (!isBook)
        _DetailActionButton(
          label: 'Playlist',
          icon: Icons.playlist_add,
          onPressed:
              () => AddToPlaylistDialog.show(context, itemIds: [item.id]),
        ),
      if (_isDownloadable(item.type) && _canUserDownload())
        _DownloadButton(item: item, viewModel: viewModel),
      if (_isDownloadable(item.type) && _canUserDownload()) _DeleteDownloadButton(item: item),
      if (item.canDelete)
        _DetailActionButton(
          label: 'Delete',
          icon: Icons.delete_outline,
          onPressed: () => _confirmDeleteItem(context, item),
          isActive: true,
          activeColor: const Color(0xFFD32F2F),
        ),
      if (item.type == 'Episode' && item.seriesId != null)
        _DetailActionButton(
          label: 'Go to Series',
          icon: Icons.tv,
          onPressed:
              () => context.push(
                Destinations.item(item.seriesId!, serverId: item.serverId),
              ),
        ),
      if ((GetIt.instance<UserRepository>().currentUser?.isAdministrator ??
              false) &&
          GetIt.instance<MediaServerClient>().serverType == ServerType.jellyfin)
        _DetailActionButton(
          label: 'Edit Metadata',
          icon: Icons.edit_note,
          onPressed: () => context.push(Destinations.adminMetadata(item.id)),
        ),
    ];

    final compact = !_useDesktopDetailLayout(context);
    final maxVisible = _calculateMaxVisibleButtons(context);
    final needsOverflow = compact && allButtons.length > maxVisible;

    if (!needsOverflow) {
      return Center(
        child: Wrap(
          spacing: 8,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: allButtons,
        ),
      );
    }

    final primaryButtons = allButtons.take(maxVisible - 1).toList();
    final extraButtons = allButtons.skip(maxVisible - 1).toList();

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ...primaryButtons,
              _DetailActionButton(
                label: _expanded ? 'Less' : 'More',
                icon: _expanded ? Icons.expand_less : Icons.expand_more,
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: extraButtons,
            ),
          ],
        ],
      ),
    );
  }

  String _formatResumePosition(Duration? position) {
    if (position == null) return '0:00';
    final h = position.inHours;
    final m = position.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  Future<void> _confirmDeleteItem(
    BuildContext context,
    AggregatedItem item,
  ) async {
    final confirmed = await _showDeleteConfirmationDialog(
      context,
      title: 'Delete Item',
      message:
          'Are you sure you want to delete "${item.name}" from the server? This action cannot be undone.',
    );
    if (!confirmed) return;

    final success = await viewModel.deleteItem();
    if (!mounted || !context.mounted) return;

    if (success) {
      if (Navigator.of(context).canPop()) {
        context.pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted')),
        );
      }
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Failed to delete item')));
  }

  int? _effectiveSubtitleStreamIndex() {
    if (_selectedSubtitleIndex != null) {
      return _selectedSubtitleIndex;
    }
    final defaultToNone = GetIt.instance<UserPreferences>().get(
      UserPreferences.subtitlesDefaultToNone,
    );
    return defaultToNone ? -1 : null;
  }

  void _play(
    BuildContext context,
    AggregatedItem item, {
    bool resume = false,
  }) async {
    final manager = GetIt.instance<PlaybackManager>();
    final subtitleStreamIndex = _effectiveSubtitleStreamIndex();

    if (item.type == 'Photo') {
      await context.push(Destinations.photo(item.id));
      return;
    }

    if (_isReadableBookItem(item)) {
      final extension = BookReaderService.detectExtension(item);
      if (extension != null &&
          !BookReaderService.isSupportedExtension(extension)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unsupported book format: .$extension')),
          );
        }
        return;
      }

      await context.push(Destinations.book(item.id, serverId: item.serverId));
      viewModel.load();
      return;
    }

    final mediaType = item.rawData['MediaType'] as String?;
    final isAudio =
        item.type == 'Audio' ||
        item.type == 'MusicAlbum' ||
        item.type == 'AudioBook' ||
        mediaType == 'Audio';

    switch (item.type) {
      case 'Series':
        final nextUp = viewModel.nextUp;
        if (nextUp == null) return;
        final startPosition =
            resume ? (nextUp.playbackPosition ?? Duration.zero) : Duration.zero;
        manager.playItems(
          [nextUp],
          startPosition: startPosition,
          audioStreamIndex: _selectedAudioIndex,
          subtitleStreamIndex: subtitleStreamIndex,
        );

      case 'Season':
        final episodes = viewModel.episodes;
        if (episodes.isEmpty) return;
        final startIndex =
            resume
                ? episodes.indexWhere(
                  (e) => (e.playedPercentage ?? 0) > 0 && !e.isPlayed,
                )
                : episodes.indexWhere((e) => !e.isPlayed);
        final idx = startIndex >= 0 ? startIndex : 0;
        final startPosition =
            resume
                ? (episodes[idx].playbackPosition ?? Duration.zero)
                : Duration.zero;
        manager.playItems(
          episodes,
          startIndex: idx,
          startPosition: startPosition,
          audioStreamIndex: _selectedAudioIndex,
          subtitleStreamIndex: subtitleStreamIndex,
        );

      case 'Episode':
        final episodes = viewModel.episodes;
        if (episodes.length > 1) {
          final startIndex = episodes.indexWhere((e) => e.id == item.id);
          final idx = startIndex >= 0 ? startIndex : 0;
          final startPosition =
              resume
                  ? (episodes[idx].playbackPosition ?? Duration.zero)
                  : Duration.zero;
          manager.playItems(
            episodes,
            startIndex: idx,
            startPosition: startPosition,
            audioStreamIndex: _selectedAudioIndex,
            subtitleStreamIndex: subtitleStreamIndex,
            mediaSourceId: widget.selectedMediaSourceId,
          );
          break;
        }
        continue defaultCase;

      case 'MusicAlbum':
        final tracks = viewModel.tracks;
        if (tracks.isEmpty) return;
        manager.playItems(tracks);

      defaultCase:
      default:
        final startPosition =
            resume ? (item.playbackPosition ?? Duration.zero) : Duration.zero;
        manager.playItems(
          [item],
          startPosition: startPosition,
          audioStreamIndex: _selectedAudioIndex,
          subtitleStreamIndex: subtitleStreamIndex,
          mediaSourceId: widget.selectedMediaSourceId,
        );
    }

    await context.push(
      isAudio ? Destinations.audioPlayer : Destinations.videoPlayer,
    );
    viewModel.load();
  }

  Future<void> _castToDevice(BuildContext context, AggregatedItem item) {
    final subtitleStreamIndex = _effectiveSubtitleStreamIndex();
    final positionTicks =
        item.playbackPosition == null
            ? null
            : item.playbackPosition!.inMicroseconds * 10;
    return showRemotePlayToSessionDialog(
      context,
      item: item,
      startPositionTicks: positionTicks,
      mediaSourceId: widget.selectedMediaSourceId,
      audioStreamIndex: _selectedAudioIndex,
      subtitleStreamIndex: subtitleStreamIndex,
    );
  }

  bool _hasTrailer(AggregatedItem item) {
    if (item.remoteTrailers.isNotEmpty) return true;
    return viewModel.features.any(_isTrailerFeatureItem);
  }

  bool _isTrailerFeatureItem(AggregatedItem feature) {
    final extraType = feature.rawData['ExtraType'] as String?;
    final type = feature.type;
    return extraType == 'Trailer' || type == 'Trailer';
  }

  AggregatedItem? _firstLocalTrailerFromFeatures(List<AggregatedItem> features) {
    for (final feature in features) {
      if (_isTrailerFeatureItem(feature) && feature.id.isNotEmpty) {
        return feature;
      }
    }
    return null;
  }

  Future<AggregatedItem?> _loadLocalTrailerOnDemand(AggregatedItem item) async {
    final client = GetIt.instance<MediaServerClient>();
    try {
      final trailers = await client.itemsApi.getLocalTrailers(item.id);
      for (final raw in trailers) {
        final id = raw['Id'] as String?;
        if (id == null || id.isEmpty) {
          continue;
        }
        return AggregatedItem(
          id: id,
          serverId: item.serverId,
          rawData: raw,
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> _playTrailer(BuildContext context, AggregatedItem item) async {
    final manager = GetIt.instance<PlaybackManager>();

    var localTrailer = _firstLocalTrailerFromFeatures(viewModel.features);
    localTrailer ??= await _loadLocalTrailerOnDemand(item);
    if (!context.mounted) return;

    if (localTrailer != null) {
      manager.playItems([localTrailer]);
      await context.push(Destinations.videoPlayer);
      viewModel.load();
      return;
    }

    final trailerUrl = item.remoteTrailers
        .map((t) => t['Url'] as String?)
        .whereType<String>()
        .firstWhere((u) => u.isNotEmpty, orElse: () => '');

    if (trailerUrl.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No playable trailer found.')),
      );
      return;
    }

    await context.push(Destinations.trailer(url: trailerUrl));
  }

  void _showAudioSelector(
    BuildContext context,
    List<Map<String, dynamic>> streams,
  ) async {
    final currentIdx =
        _selectedAudioIndex != null
            ? streams.indexWhere((s) => s['Index'] == _selectedAudioIndex)
            : streams.indexWhere((s) => s['IsDefault'] == true);
    final result = await TrackSelectorDialog.show(
      context,
      title: 'Audio Track',
      options:
          streams.map((s) {
            final display =
                s['DisplayTitle'] as String? ??
                s['Language'] as String? ??
                'Unknown';
            final codec = s['Codec'] as String?;
            return TrackOption(label: display, subtitle: codec?.toUpperCase());
          }).toList(),
      selectedIndex: currentIdx >= 0 ? currentIdx : null,
    );
    if (result != null && result < streams.length) {
      setState(() => _selectedAudioIndex = streams[result]['Index'] as int?);
    }
  }

  bool _canDownloadRemoteSubtitles(AggregatedItem item) {
    final client = GetIt.instance<MediaServerClient>();
    final user = GetIt.instance<UserRepository>().currentUser;
    final mediaType = item.rawData['MediaType'] as String?;
    final isAudio =
        item.type == 'Audio' ||
        item.type == 'MusicAlbum' ||
        item.type == 'AudioBook' ||
        mediaType == 'Audio';

    return client.serverType == ServerType.jellyfin &&
        (user?.canManageSubtitles ?? false) &&
        item.mediaSources.isNotEmpty &&
        item.type != 'Photo' &&
        !_isReadableBookItem(item) &&
        !isAudio;
  }

  String _remoteSubtitleErrorMessage(
    Object error, {
    required String action,
  }) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 403) {
        return 'Remote subtitle $action requires the Jellyfin subtitle management permission for this user.';
      }
      if (status == 404) {
        return 'This item could not be found on the server for remote subtitle $action.';
      }

      final data = error.response?.data;
      String? detail;
      if (data is Map) {
        detail = (data['message'] ?? data['Message'] ?? data['error'] ?? data['Error'])
            as String?;
      } else if (data is String && data.trim().isNotEmpty) {
        detail = data.trim();
      }

      if (detail != null && detail.isNotEmpty) {
        return 'Remote subtitle $action failed: $detail';
      }
      if (status != null) {
        return 'Remote subtitle $action failed (HTTP $status).';
      }
    }

    return 'Failed to $action remote subtitles.';
  }

  String _remoteSubtitleLanguage(
    List<Map<String, dynamic>> subtitleStreams,
    List<Map<String, dynamic>> audioStreams,
  ) {
    final preferred =
        GetIt.instance<UserPreferences>()
            .get(UserPreferences.defaultSubtitleLanguage)
            .trim();
    if (preferred.isNotEmpty) {
      return preferred;
    }

    for (final stream in [...subtitleStreams, ...audioStreams]) {
      final language = (stream['Language'] as String?)?.trim();
      if (language != null && language.isNotEmpty) {
        return language;
      }
    }

    return 'eng';
  }

  String _remoteSubtitleOptionSubtitle(Map<String, dynamic> subtitle) {
    final details = <String>[];
    final language =
        (subtitle['ThreeLetterISOLanguageName'] as String?)?.trim() ??
        (subtitle['Language'] as String?)?.trim();
    final provider = subtitle['ProviderName'] as String?;
    final format = subtitle['Format'] as String?;
    final downloadCount = subtitle['DownloadCount'] as num?;
    final rating = subtitle['CommunityRating'] as num?;
    final isHashMatch = subtitle['IsHashMatch'] == true;

    if (language != null && language.isNotEmpty) {
      details.add(language.toUpperCase());
    }

    if (provider != null && provider.isNotEmpty) {
      details.add(provider);
    }
    if (format != null && format.isNotEmpty) {
      details.add(format.toUpperCase());
    }
    if (rating != null) {
      details.add('${rating.toStringAsFixed(1)}★');
    }
    if (downloadCount != null) {
      details.add('${downloadCount.toInt()} downloads');
    }
    if (isHashMatch) {
      details.add('Perfect match');
    }

    return details.join(' | ');
  }

  Future<List<Map<String, dynamic>>> _refreshSubtitleStreams(
    AggregatedItem currentItem,
    Set<int> existingIndexes,
  ) async {
    const attempts = 8;
    const delay = Duration(milliseconds: 500);
    List<Map<String, dynamic>> latestStreams = currentItem.mediaStreams
        .where((stream) => stream['Type'] == 'Subtitle')
        .toList(growable: false);

    for (var attempt = 0; attempt < attempts; attempt++) {
      await viewModel.load();
      if (!mounted) {
        return latestStreams;
      }

      final refreshedItem = viewModel.item;
      if (refreshedItem != null) {
        final mediaSource = _selectedMediaSourceForItem(
          refreshedItem,
          widget.selectedMediaSourceId,
        );
        latestStreams = _mediaStreamsForItem(refreshedItem, mediaSource)
            .where((stream) => stream['Type'] == 'Subtitle')
            .toList(growable: false);
        final hasNewStream = latestStreams.any((stream) {
          final index = stream['Index'] as int?;
          return index != null && !existingIndexes.contains(index);
        });
        if (hasNewStream) {
          return latestStreams;
        }
      }

      if (attempt < attempts - 1) {
        await Future.delayed(delay);
      }
    }

    return latestStreams;
  }

  Map<String, dynamic>? _findNewSubtitleStream(
    Set<int> existingIndexes,
    List<Map<String, dynamic>> after,
  ) {
    for (final stream in after) {
      final index = stream['Index'] as int?;
      if (index != null && !existingIndexes.contains(index)) {
        return stream;
      }
    }

    return null;
  }

  Future<void> _downloadRemoteSubtitles(
    BuildContext context,
    AggregatedItem item,
    List<Map<String, dynamic>> subtitleStreams,
    List<Map<String, dynamic>> audioStreams,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final client = GetIt.instance<MediaServerClient>();
    final language = _remoteSubtitleLanguage(subtitleStreams, audioStreams);

    List<Map<String, dynamic>> results;
    try {
      results = await client.itemsApi.searchRemoteSubtitles(
        item.id,
        language: language,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _remoteSubtitleErrorMessage(error, action: 'search'),
          ),
        ),
      );
      return;
    }

    if (!context.mounted) {
      return;
    }
    if (results.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text('No remote subtitles found for $language.')),
      );
      return;
    }

    final result = await TrackSelectorDialog.show(
      context,
      title: 'Download Subtitles',
      options:
          results.map((subtitle) {
            final label =
                subtitle['Name'] as String? ??
                subtitle['Author'] as String? ??
                'Subtitle';
            final subtitleText = _remoteSubtitleOptionSubtitle(subtitle);
            return TrackOption(
              label: label,
              subtitle: subtitleText.isNotEmpty ? subtitleText : null,
            );
          }).toList(),
    );

    if (!context.mounted || result == null || result >= results.length) {
      return;
    }

    final subtitleId = results[result]['Id'] as String?;
    if (subtitleId == null || subtitleId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('The selected subtitle is invalid.')),
      );
      return;
    }

    try {
      await client.itemsApi.downloadRemoteSubtitle(item.id, subtitleId);
      if (!context.mounted) {
        return;
      }

      final existingIndexes = subtitleStreams
          .map((stream) => stream['Index'] as int?)
          .whereType<int>()
          .toSet();

      final refreshedSubtitleStreams = await _refreshSubtitleStreams(
        item,
        existingIndexes,
      );
      if (!context.mounted) {
        return;
      }

      final newStream = _findNewSubtitleStream(
        existingIndexes,
        refreshedSubtitleStreams,
      );

      if (newStream != null) {
        setState(() => _selectedSubtitleIndex = newStream['Index'] as int?);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Subtitle downloaded and selected: ${newStream['DisplayTitle'] as String? ?? newStream['Title'] as String? ?? newStream['Language'] as String? ?? 'Unknown'}',
            ),
          ),
        );
        return;
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Subtitle downloaded. It may take a moment to appear while Jellyfin refreshes the item.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _remoteSubtitleErrorMessage(error, action: 'download'),
          ),
        ),
      );
    }
  }

  void _showSubtitleSelector(
    BuildContext context,
    AggregatedItem item,
    List<Map<String, dynamic>> streams,
    List<Map<String, dynamic>> audioStreams,
  ) async {
    final canDownloadRemote = _canDownloadRemoteSubtitles(item);
    final currentIdx =
        _selectedSubtitleIndex != null
            ? (_selectedSubtitleIndex == -1
                ? 0
                : streams.indexWhere(
                      (s) => s['Index'] == _selectedSubtitleIndex,
                    ) +
                    1)
            : (streams.indexWhere((s) => s['IsDefault'] == true) + 1);
    final options = [
      const TrackOption(label: 'None'),
      ...streams.map((s) {
        final display =
            s['DisplayTitle'] as String? ??
            s['Language'] as String? ??
            'Unknown';
        final codec = s['Codec'] as String?;
        return TrackOption(label: display, subtitle: codec?.toUpperCase());
      }),
    ];
    final downloadOptionIndex = canDownloadRemote ? options.length : null;
    if (canDownloadRemote) {
      options.add(
        const TrackOption(
          label: 'Download subtitles...',
          subtitle: 'Search using the OpenSubtitles plugin',
        ),
      );
    }
    final result = await TrackSelectorDialog.show(
      context,
      title: 'Subtitle Track',
      options: options,
      selectedIndex: currentIdx >= 0 ? currentIdx : 0,
    );
    if (result != null) {
      if (downloadOptionIndex != null && result == downloadOptionIndex) {
        await _downloadRemoteSubtitles(context, item, streams, audioStreams);
        return;
      }
      if (result == 0) {
        setState(() => _selectedSubtitleIndex = -1);
      } else if (result - 1 < streams.length) {
        setState(
          () => _selectedSubtitleIndex = streams[result - 1]['Index'] as int?,
        );
      }
    }
  }

  void _showVersionSelector(
    BuildContext context,
    List<Map<String, dynamic>> sources,
  ) async {
    final currentIdx =
      widget.selectedMediaSourceId != null
        ? sources.indexWhere((s) => s['Id'] == widget.selectedMediaSourceId)
            : 0;
    final result = await TrackSelectorDialog.show(
      context,
      title: 'Select Version',
      options:
          sources.asMap().entries.map((entry) {
            final s = entry.value;
            final name =
                s['Name'] as String? ?? 'Version ${entry.key + 1}';
            final bitrate = s['Bitrate'] as int?;
            final container = s['Container'] as String?;
            final subtitle = [
              if (container != null) container.toUpperCase(),
              if (bitrate != null) '${(bitrate / 1000000).toStringAsFixed(1)} Mbps',
            ].join(' | ');
            return TrackOption(
              label: name,
              subtitle: subtitle.isNotEmpty ? subtitle : null,
            );
          }).toList(),
      selectedIndex: currentIdx >= 0 ? currentIdx : 0,
    );
    if (result != null && result < sources.length) {
      final id = sources[result]['Id'] as String?;
      widget.onSelectedMediaSourceChanged(id);
    }
  }
}

Map<String, dynamic>? _selectedMediaSourceForItem(
  AggregatedItem item,
  String? selectedMediaSourceId,
) {
  if (item.mediaSources.isEmpty) {
    return null;
  }
  if (selectedMediaSourceId == null || selectedMediaSourceId.isEmpty) {
    return item.mediaSources.first;
  }
  for (final source in item.mediaSources) {
    final id = source['Id'] as String?;
    if (id == selectedMediaSourceId) {
      return source;
    }
  }
  return item.mediaSources.first;
}

List<Map<String, dynamic>> _mediaStreamsForItem(
  AggregatedItem item,
  Map<String, dynamic>? mediaSource,
) {
  final rawStreams = mediaSource?['MediaStreams'];
  if (rawStreams is List) {
    final parsed =
        rawStreams
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList(growable: false);
    if (parsed.isNotEmpty) {
      return parsed;
    }
  }
  return item.mediaStreams;
}

Duration? _runtimeForItem(AggregatedItem item, Map<String, dynamic>? mediaSource) {
  final ticks = mediaSource?['RunTimeTicks'];
  if (ticks is num && ticks > 0) {
    return Duration(microseconds: (ticks ~/ 10));
  }
  return item.runtime;
}

String? _endsAt(AggregatedItem item, Duration? runtime, {required bool use24Hour}) {
  if (runtime == null) {
    return null;
  }
  final percentage = item.playedPercentage;
  final Duration left;
  if (percentage != null && percentage > 0) {
    left = Duration(
      microseconds: (runtime.inMicroseconds * (1.0 - percentage / 100.0)).round(),
    );
  } else {
    left = runtime;
  }
  final end = DateTime.now().add(left);
  final hour = end.hour;
  final minute = end.minute.toString().padLeft(2, '0');
  if (use24Hour) {
    return '${hour.toString().padLeft(2, '0')}:$minute';
  }
  final amPm = hour >= 12 ? 'PM' : 'AM';
  final h12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
  return '$h12:$minute $amPm';
}

String? _resolutionFromStreams(List<Map<String, dynamic>> streams) {
  final video = streams.where((s) => s['Type'] == 'Video').firstOrNull;
  if (video == null) {
    return null;
  }
  final width = video['Width'] as int?;
  final height = video['Height'] as int?;
  if (width == null || height == null || width <= 0 || height <= 0) {
    return null;
  }

  final interlaced = video['IsInterlaced'] == true;
  final suffix = interlaced ? 'i' : 'p';

  if (width >= 7600 || height >= 4300) return '8K';
  if (width >= 3800 || height >= 2000) return '4K';
  if (width >= 2500 || height >= 1400) return '1440$suffix';
  if (width >= 1800 || height >= 1000) return '1080$suffix';
  if (width >= 1200 || height >= 700) return '720$suffix';
  if (width >= 600 || height >= 400) return '480$suffix';
  return 'SD';
}

String? _hdrFromStreams(List<Map<String, dynamic>> streams) {
  final video = streams.where((s) => s['Type'] == 'Video').firstOrNull;
  if (video == null) {
    return null;
  }
  final hdr = video['VideoRangeType'] as String?;
  if (hdr == null || hdr.isEmpty) {
    return null;
  }
  return hdr.toUpperCase();
}

String? _audioLabelFromStreams(List<Map<String, dynamic>> streams) {
  final audio = streams.where((s) => s['Type'] == 'Audio').firstOrNull;
  if (audio == null) return null;
  return audioLabelFromProfileCodec(
      audio['Profile'] as String?, audio['Codec'] as String?);
}

String? _codecFromStreams(List<Map<String, dynamic>> streams, String streamType) {
  final stream = streams.where((s) => s['Type'] == streamType).firstOrNull;
  final codec = stream?['Codec'] as String?;
  if (codec == null || codec.isEmpty) {
    return null;
  }
  return codec.toUpperCase();
}

String? _channelLayoutFromStreams(List<Map<String, dynamic>> streams) {
  final audio = streams.where((s) => s['Type'] == 'Audio').firstOrNull;
  if (audio == null) {
    return null;
  }
  final layout = audio['ChannelLayout'] as String?;
  if (layout != null && layout.isNotEmpty) {
    return layout;
  }
  final channels = audio['Channels'];
  if (channels is int) {
    return switch (channels) {
      1 => 'Mono',
      2 => 'Stereo',
      6 => '5.1',
      8 => '7.1',
      _ => '${channels}ch',
    };
  }
  return null;
}

bool _isReadableBookItem(AggregatedItem item) {
  final mediaType = item.rawData['MediaType'] as String?;
  return item.type == 'Book' && mediaType != 'Audio';
}

bool _isDownloadable(String? type) {
  return type == 'Movie' ||
      type == 'Audio' ||
      type == 'AudioBook' ||
      type == 'Book' ||
      type == 'Episode' ||
      type == 'Season' ||
      type == 'Series';
}

bool _canUserDownload() {
  final user = GetIt.instance<UserRepository>().currentUser;
  return user?.canDownload ?? false;
}

class _DownloadButton extends StatefulWidget {
  final AggregatedItem item;
  final ItemDetailViewModel viewModel;

  const _DownloadButton({required this.item, required this.viewModel});

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  bool _isOffline = false;
  DownloadService? _downloadService;

  String _originalQualitySubtitle(AggregatedItem item, {required bool isMulti}) {
    if (isMulti) {
      return 'Original files, no re-encoding';
    }

    final mediaSource = item.mediaSources.isNotEmpty ? item.mediaSources.first : null;
    final sizeBytes = sourceSizeBytes(item);
    final container = (mediaSource?['Container'] as String?)?.toUpperCase();
    final videoCodec = item.videoCodec?.toUpperCase();
    final audioCodec = item.audioCodec?.toUpperCase();

    final details = <String>[];
    if (sizeBytes > 0) {
      details.add(formatBytes(sizeBytes));
    }
    if (container != null && container.isNotEmpty) {
      details.add(container);
    }
    if (videoCodec != null && audioCodec != null) {
      details.add('$videoCodec/$audioCodec');
    } else if (videoCodec != null) {
      details.add(videoCodec);
    } else if (audioCodec != null) {
      details.add(audioCodec);
    }

    if (details.isEmpty) {
      return 'Original file, no re-encoding';
    }

    return details.join(' • ');
  }

  String _qualitySubtitle(
    AggregatedItem item,
    DownloadQuality quality, {
    required bool supportsTranscoding,
    required bool isMulti,
  }) {
    if (!quality.isTranscoded || !supportsTranscoding) {
      return _originalQualitySubtitle(item, isMulti: isMulti);
    }

    if (isMulti) {
      return '${quality.estimatedSizePerHour} • ${quality.encodingInfo}';
    }

    final estimateBytes = estimateTranscodedSizeBytes(item, quality);
    if (estimateBytes != null) {
      return '~${formatBytes(estimateBytes)} • ${quality.encodingInfo}';
    }

    return '${quality.estimatedSizePerHour} • ${quality.encodingInfo}';
  }

  @override
  void initState() {
    super.initState();
    if (GetIt.instance.isRegistered<DownloadService>()) {
      _downloadService = GetIt.instance<DownloadService>();
      _downloadService!.addListener(_onChanged);
    }
    _checkOffline();
  }

  @override
  void dispose() {
    _downloadService?.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => _checkOffline();

  Future<void> _checkOffline() async {
    final repo = GetIt.instance<OfflineRepository>();
    final available = await repo.isAvailableOffline(widget.item.id);
    if (mounted && available != _isOffline) {
      setState(() => _isOffline = available);
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadService = _downloadService ?? GetIt.instance<DownloadService>();
    return ListenableBuilder(
      listenable: downloadService,
      builder: (context, _) {
        final item = widget.item;
        final isMulti = item.type == 'Season' || item.type == 'Series';
        final progress = downloadService.activeDownloads[item.id];
        final isBatch = downloadService.isBatchDownloading;

        if (progress != null &&
            !progress.isComplete &&
            progress.error == null) {
          final label =
              progress.progress >= 0
                  ? '${(progress.progress * 100).toInt()}%'
                  : '${(progress.bytesReceived / 1048576).toStringAsFixed(1)} MB';
          return _DetailActionButton(
            label: label,
            icon: Icons.close,
            onPressed: () => downloadService.cancelDownload(item.id),
            isActive: true,
            activeColor: const Color(0xFF00A4DC),
          );
        }

        if (isBatch && isMulti) {
          final done = downloadService.completedCount;
          final total = downloadService.totalQueued;
          var pct = '';
          for (final progress in downloadService.activeDownloads.values) {
            if (!progress.isComplete && progress.error == null) {
              if (progress.progress >= 0) {
                pct = '${(progress.progress * 100).toInt()}%';
              }
              break;
            }
          }
          return _DetailActionButton(
            label: '${done + 1}/$total${pct.isNotEmpty ? ' · $pct' : ''}',
            icon: Icons.close,
            onPressed: () => downloadService.cancelAll(),
            isActive: true,
            activeColor: const Color(0xFF00A4DC),
          );
        }

        if (_isOffline || (progress != null && progress.isComplete)) {
          return _DetailActionButton(
            label: 'Downloaded',
            icon: Icons.download_done,
            isActive: true,
            activeColor: const Color(0xFF4CAF50),
            onPressed: () => _showQualityPicker(context, downloadService),
          );
        }

        return _DetailActionButton(
          label: isMulti ? 'Download All' : 'Download',
          icon: Icons.download,
          onPressed: () => _showQualityPicker(context, downloadService),
        );
      },
    );
  }

  void _showQualityPicker(BuildContext context, DownloadService service) {
    final item = widget.item;
    final isMulti = item.type == 'Season' || item.type == 'Series';
    final supportsTranscoding = item.type == 'Movie' || item.type == 'Episode';

    if (!isMulti && !supportsTranscoding) {
      _startDownload(context, service, DownloadQuality.original);
      return;
    }

    final sourceWidth = isMulti ? null : item.sourceVideoWidth;
    final availableQualities =
        supportsTranscoding
            ? DownloadQuality.values.where((q) {
              if (q.maxWidth == null) return true;
              if (sourceWidth == null) return true;
              return q.maxWidth! <= sourceWidth;
            }).toList()
            : [DownloadQuality.original];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    isMulti ? 'Download All — Quality' : 'Download Quality',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...availableQualities.map(
                  (quality) => ListTile(
                    leading: Icon(
                      quality.isTranscoded
                          ? Icons.compress
                          : Icons.file_copy_outlined,
                      color: Colors.white70,
                    ),
                    title: Text(
                      quality.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      _qualitySubtitle(
                        item,
                        quality,
                        supportsTranscoding: supportsTranscoding,
                        isMulti: isMulti,
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _startDownload(context, service, quality);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  void _startDownload(
    BuildContext context,
    DownloadService service,
    DownloadQuality quality,
  ) {
    final item = widget.item;
    switch (item.type) {
      case 'Movie':
      case 'Episode':
      case 'Audio':
      case 'AudioBook':
      case 'Book':
        service.downloadItem(item, quality: quality);
      case 'Season':
        final episodes = widget.viewModel.episodes;
        if (episodes.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No episodes loaded')));
          return;
        }
        service.downloadItems(episodes, quality: quality);
      case 'Series':
        service.downloadSeries(item.id, quality: quality);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${item.name} (${quality.label})...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _DeleteDownloadButton extends StatefulWidget {
  final AggregatedItem item;

  const _DeleteDownloadButton({required this.item});

  @override
  State<_DeleteDownloadButton> createState() => _DeleteDownloadButtonState();
}

class _DeleteDownloadButtonState extends State<_DeleteDownloadButton> {
  bool _hasFiles = false;
  bool _checking = true;
  DownloadService? _downloadService;

  @override
  void initState() {
    super.initState();
    if (GetIt.instance.isRegistered<DownloadService>()) {
      _downloadService = GetIt.instance<DownloadService>();
      _downloadService!.addListener(_onDownloadChanged);
    }
    _checkFiles();
  }

  @override
  void dispose() {
    _downloadService?.removeListener(_onDownloadChanged);
    super.dispose();
  }

  void _onDownloadChanged() => _checkFiles();

  Future<void> _checkFiles() async {
    final service = GetIt.instance<DownloadService>();
    final exists = await service.hasDownloadedFiles(widget.item);
    if (mounted) {
      setState(() {
        _hasFiles = exists;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking || !_hasFiles) return const SizedBox.shrink();

    return _DetailActionButton(
      label: 'Delete Files',
      icon: Icons.delete_outline,
      onPressed: () => _confirmDelete(context),
      isActive: true,
      activeColor: const Color(0xFFFF4757),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final item = widget.item;
    final typeLabel = switch (item.type) {
      'Series' =>
        'all downloaded episodes for "${item.seriesName ?? item.name}"',
      'Season' => 'all downloaded episodes in this season',
      _ => '"${item.name}"',
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              'Delete Downloaded Files',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Delete local files for $typeLabel?\n\nThis will free up storage space. You can re-download later.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF4757),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      final service = GetIt.instance<DownloadService>();
      final success = await service.deleteDownloadedFiles(item);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Downloaded files deleted' : 'Failed to delete files',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        if (success) {
          setState(() => _hasFiles = false);
        }
      }
    }
  }
}

class _DetailActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;
  final Color? activeColor;

  const _DetailActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    this.activeColor,
  });

  @override
  State<_DetailActionButton> createState() => _DetailActionButtonState();
}

class _DetailActionButtonState extends State<_DetailActionButton> with FocusStateMixin {

  @override
  Widget build(BuildContext context) {
    final isMobile = _isCompact(context);
    final focusColor =
        Color(GetIt.instance<UserPreferences>().get(UserPreferences.focusColor).colorValue);
    final showHighlight = showFocusBorder;

    final activeColor = widget.isActive ? widget.activeColor : null;
    final iconColor = showHighlight
        ? Colors.black
        : (widget.isActive ? (widget.activeColor ?? Colors.white) : Colors.white);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: Focus(
        onFocusChange: (focused) => setFocused(focused),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: SizedBox(
            width: isMobile ? 80 : 96,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isMobile ? 44 : 52,
                  height: isMobile ? 44 : 52,
                  decoration: BoxDecoration(
                    color: showHighlight
                        ? Colors.white
                        : activeColor != null
                            ? activeColor.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.08),
                    border: Border.all(
                      color: showHighlight
                          ? Colors.white
                          : activeColor?.withValues(alpha: 0.4) ??
                              focusColor.withValues(alpha: 0.35),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.icon,
                    color: iconColor,
                    size: isMobile ? 20 : 22,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        shadows: _textShadows,
        fontSize: _isCompact(context) ? 17 : null,
      ),
    );
  }
}

class _CastRow extends StatelessWidget {
  final List<Map<String, dynamic>> people;
  final ImageApi imageApi;
  final String? serverId;
  final ScrollController? scrollController;

  const _CastRow({required this.people, required this.imageApi, this.serverId, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final isMobile = _isCompact(context);
    final cardWidth = isMobile ? 80.0 : 100.0;
    final avatarRadius = isMobile ? 35.0 : 45.0;

    return SizedBox(
      height: isMobile ? 158 : 178,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
        itemCount: people.length,
        separatorBuilder: (_, __) => SizedBox(width: isMobile ? 12 : 16),
        itemBuilder: (context, index) {
          final person = people[index];
          final name = person['Name'] as String? ?? '';
          final role = person['Role'] as String?;
          final personId = person['Id'] as String?;
          final tag = person['PrimaryImageTag'] as String?;

          String? imageUrl;
          if (personId != null && tag != null) {
            imageUrl = imageApi.getPrimaryImageUrl(
              personId,
              maxHeight: isMobile ? 140 : 200,
              tag: tag,
            );
          }

          return _CastPersonCard(
            cardWidth: cardWidth,
            avatarRadius: avatarRadius,
            name: name,
            role: role,
            imageUrl: imageUrl,
            isMobile: isMobile,
            onTap: personId != null
                ? () => context.push(
                      Destinations.item(personId, serverId: serverId),
                    )
                : null,
          );
        },
      ),
    );
  }
}

class _CastPersonCard extends StatefulWidget {
  final double cardWidth;
  final double avatarRadius;
  final String name;
  final String? role;
  final String? imageUrl;
  final bool isMobile;
  final VoidCallback? onTap;

  const _CastPersonCard({
    required this.cardWidth,
    required this.avatarRadius,
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.isMobile,
    this.onTap,
  });

  @override
  State<_CastPersonCard> createState() => _CastPersonCardState();
}

class _CastPersonCardState extends State<_CastPersonCard> with FocusStateMixin {

  @override
  Widget build(BuildContext context) {
    final cardExpansion =
        GetIt.instance<UserPreferences>().get(UserPreferences.cardFocusExpansion);
    final focusColor =
        Color(GetIt.instance<UserPreferences>().get(UserPreferences.focusColor).colorValue);

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: Focus(
        onFocusChange: (focused) => setFocused(focused),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: cardExpansion && showFocusBorder ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 120),
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: widget.cardWidth,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: showFocusBorder
                          ? Border.all(color: focusColor, width: 1.5)
                          : null,
                    ),
                    child: CircleAvatar(
                      radius: widget.avatarRadius,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      backgroundImage: widget.imageUrl != null
                          ? CachedNetworkImageProvider(widget.imageUrl!)
                          : null,
                      child: widget.imageUrl == null
                          ? Icon(
                              Icons.person,
                              color: Colors.white54,
                              size: widget.isMobile ? 24 : 32,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: widget.isMobile ? 11 : null,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.role != null)
                    Text(
                      widget.role!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: widget.isMobile ? 10 : 11,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SimilarRow extends StatelessWidget {
  final List<AggregatedItem> items;
  final ImageApi imageApi;
  final UserPreferences prefs;
  final ScrollController? scrollController;

  const _SimilarRow({
    required this.items,
    required this.imageApi,
    required this.prefs,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final watchedBehavior = prefs.get(UserPreferences.watchedIndicatorBehavior);
    final cardExpansion = prefs.get(UserPreferences.cardFocusExpansion);
    final isMobile = _isCompact(context);
    final cardWidth = isMobile ? 120.0 : 150.0;

    return SizedBox(
      height: isMobile ? 228 : 282,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: isMobile ? 8 : 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final ar = MediaCard.aspectRatioForType(item.type);
          return MediaCard(
            title: item.name,
            imageUrl:
                item.primaryImageTag != null
                    ? imageApi.getPrimaryImageUrl(
                      item.id,
                      maxHeight: isMobile ? 300 : 400,
                      tag: item.primaryImageTag,
                    )
                    : null,
            width: cardWidth,
            aspectRatio: ar,
            focusColor: Color(prefs.get(UserPreferences.focusColor).colorValue),
            cardFocusExpansion: cardExpansion,
            isFavorite: item.isFavorite,
            isPlayed: item.isPlayed,
            playedPercentage: item.playedPercentage,
            watchedBehavior: watchedBehavior,
            itemType: item.type,
            onTap:
                () => context.push(
                  Destinations.item(item.id, serverId: item.serverId),
                ),
          );
        },
      ),
    );
  }
}

class _FeaturesRow extends StatelessWidget {
  final List<AggregatedItem> items;
  final ImageApi imageApi;
  final UserPreferences prefs;
  final ScrollController? scrollController;

  const _FeaturesRow({
    required this.items,
    required this.imageApi,
    required this.prefs,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final watchedBehavior = prefs.get(UserPreferences.watchedIndicatorBehavior);
    final cardExpansion = prefs.get(UserPreferences.cardFocusExpansion);
    final isMobile = _isCompact(context);
    final cardWidth = isMobile ? 140.0 : 170.0;

    return SizedBox(
      height: isMobile ? 230 : 280,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: isMobile ? 8 : 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return MediaCard(
            title: item.name,
            subtitle: item.subtitle,
            imageUrl:
                item.primaryImageTag != null
                    ? imageApi.getPrimaryImageUrl(
                      item.id,
                      maxHeight: isMobile ? 300 : 400,
                      tag: item.primaryImageTag,
                    )
                    : null,
            width: cardWidth,
            aspectRatio: MediaCard.aspectRatioForType(item.type),
            focusColor: Color(prefs.get(UserPreferences.focusColor).colorValue),
            cardFocusExpansion: cardExpansion,
            isFavorite: item.isFavorite,
            isPlayed: item.isPlayed,
            playedPercentage: item.playedPercentage,
            watchedBehavior: watchedBehavior,
            itemType: item.type,
            onTap:
                () => context.push(
                  Destinations.item(item.id, serverId: item.serverId),
                ),
          );
        },
      ),
    );
  }
}

class _ChaptersRow extends StatelessWidget {
  final AggregatedItem item;
  final ImageApi imageApi;
  final ValueChanged<Duration> onPlayFromChapter;
  final ScrollController? scrollController;

  const _ChaptersRow({
    required this.item,
    required this.imageApi,
    required this.onPlayFromChapter,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final chapters = item.chapters;
    final isMobile = _isCompact(context);
    final chapterCardWidth = isMobile ? 220.0 : 280.0;
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final chapterImageWidth = (chapterCardWidth * devicePixelRatio).ceil();

    return SizedBox(
      height: isMobile ? 180 : 210,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        itemCount: chapters.length,
        separatorBuilder: (_, __) => SizedBox(width: isMobile ? 8 : 12),
        itemBuilder: (context, index) {
          final chapter = chapters[index];
          final ticks = chapter['StartPositionTicks'] as int? ?? 0;
          final position = Duration(microseconds: ticks ~/ 10);
          final name =
              (chapter['Name'] as String?)?.trim().isNotEmpty == true
                  ? (chapter['Name'] as String)
                  : 'Chapter ${index + 1}';
          final imageTag = chapter['ImageTag'] as String?;
          final chapterImageUrl = imageApi.getChapterImageUrl(
            item.id,
            index: index,
            maxWidth: chapterImageWidth,
            tag: imageTag,
          );

          return SizedBox(
            width: chapterCardWidth,
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onPlayFromChapter(position),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: SizedBox(
                          width: double.infinity,
                          child: Image.network(
                            chapterImageUrl,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            errorBuilder:
                                (_, __, ___) => Container(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.movie,
                                    size: isMobile ? 22 : 26,
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$name - ${_formatDuration(position)}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) {
      return '$h:$m:$s';
    }
    return '${d.inMinutes}:$s';
  }
}

class _MetadataSection extends StatelessWidget {
  final ItemDetailViewModel viewModel;

  const _MetadataSection({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final item = viewModel.item!;
    final entries = <MapEntry<String, String>>[];

    if (viewModel.directors.isNotEmpty) {
      entries.add(
        MapEntry(
          'DIRECTOR',
          viewModel.directors.map((d) => d['Name'] as String).join(', '),
        ),
      );
    }
    if (viewModel.writers.isNotEmpty) {
      entries.add(
        MapEntry(
          'WRITERS',
          viewModel.writers.map((w) => w['Name'] as String).join(', '),
        ),
      );
    }
    if (item.studios.isNotEmpty) {
      final studioNames = item.studios.map((s) => s['Name'] as String).toList();
      final display =
          studioNames.length > 5
              ? '${studioNames.take(5).join(', ')} +${studioNames.length - 5} more'
              : studioNames.join(', ');
      entries.add(MapEntry('STUDIO', display));
    }

    if (entries.isEmpty) return const SizedBox.shrink();

    final isMobile = _isCompact(context);
    final cellPadding =
        isMobile
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 14);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(12),
      ),
      child:
          isMobile
              ? Wrap(
                children:
                    entries.asMap().entries.map((e) {
                      final entry = e.value;
                      return FractionallySizedBox(
                        widthFactor: entries.length <= 2 ? 1.0 : 0.5,
                        child: Padding(
                          padding: cellPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: Theme.of(
                                  context,
                                ).textTheme.labelSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.value,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              )
              : IntrinsicHeight(
                child: Row(
                  children: [
                    ...entries.asMap().entries.map((e) {
                      final index = e.key;
                      final entry = e.value;
                      return Expanded(
                        child: Row(
                          children: [
                            if (index > 0)
                              Container(
                                width: 1,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.value,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
    );
  }
}

class _OverviewText extends StatelessWidget {
  final String text;

  const _OverviewText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Colors.white.withValues(alpha: 0.9),
        shadows: _textShadows,
        height: 1.5,
      ),
    );
  }
}

class _EpisodeProgressBar extends StatelessWidget {
  final double percentage;

  const _EpisodeProgressBar({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: LinearProgressIndicator(
        value: percentage / 100.0,
        minHeight: 3,
        backgroundColor: Colors.black38,
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00A4DC)),
      ),
    );
  }
}

class _SeasonsRow extends StatelessWidget {
  final List<AggregatedItem> seasons;
  final ImageApi imageApi;
  final UserPreferences prefs;
  final ScrollController? scrollController;

  const _SeasonsRow({
    required this.seasons,
    required this.imageApi,
    required this.prefs,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final watchedBehavior = prefs.get(UserPreferences.watchedIndicatorBehavior);
    final cardExpansion = prefs.get(UserPreferences.cardFocusExpansion);
    final isMobile = _isCompact(context);
    final cardWidth = isMobile ? 120.0 : 150.0;

    return SizedBox(
      height: isMobile ? 230 : 290,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        itemCount: seasons.length,
        separatorBuilder: (_, __) => SizedBox(width: isMobile ? 8 : 12),
        itemBuilder: (context, index) {
          final season = seasons[index];
          return MediaCard(
            title: season.name,
            subtitle: _progressText(season),
            imageUrl: _seasonImageUrl(season, isMobile: isMobile),
            width: cardWidth,
            aspectRatio: 2 / 3,
            focusColor: Color(prefs.get(UserPreferences.focusColor).colorValue),
            cardFocusExpansion: cardExpansion,
            isPlayed: season.isPlayed,
            unplayedCount: season.unplayedItemCount,
            watchedBehavior: watchedBehavior,
            itemType: season.type,
            onTap:
                () => context.push(
                  Destinations.item(season.id, serverId: season.serverId),
                ),
          );
        },
      ),
    );
  }

  String? _seasonImageUrl(AggregatedItem season, {required bool isMobile}) {
    final primaryHeight = isMobile ? 300 : 400;
    final secondaryWidth = isMobile ? 200 : 260;

    String? primary(String? id, String? tag) {
      if (id == null || tag == null) return null;
      return imageApi.getPrimaryImageUrl(id, maxHeight: primaryHeight, tag: tag);
    }

    String? thumb(String? id, String? tag) {
      if (id == null) return null;
      return imageApi.getThumbImageUrl(id, maxWidth: secondaryWidth, tag: tag);
    }

    String? backdrop(String? id, List<String> tags) {
      if (id == null || tags.isEmpty) return null;
      return imageApi.getBackdropImageUrl(
        id,
        maxWidth: secondaryWidth,
        index: 0,
        tag: tags.first,
      );
    }

    return primary(season.id, season.primaryImageTag) ??
        primary(season.seriesId, season.seriesPrimaryImageTag) ??
        primary(season.primaryImageItemId, season.primaryImageTagField) ??
        primary(season.parentPrimaryImageItemId, season.parentPrimaryImageTag) ??
        thumb(season.id, season.thumbImageTag) ??
        backdrop(season.id, season.backdropImageTags) ??
        thumb(season.seriesId, season.seriesThumbImageTag) ??
        thumb(season.parentThumbItemId, season.parentThumbImageTag) ??
        backdrop(season.parentBackdropItemId, season.parentBackdropImageTags);
  }

  String? _progressText(AggregatedItem season) {
    final total = season.childCount;
    final unplayed = season.unplayedItemCount;
    if (total == null) return null;
    if (unplayed == null || unplayed == 0) return '$total Episodes';
    final watched = total - unplayed;
    return '$watched / $total';
  }
}

class _EpisodesRow extends StatelessWidget {
  final List<AggregatedItem> episodes;
  final String currentEpisodeId;
  final ImageApi imageApi;
  final ScrollController? scrollController;

  const _EpisodesRow({
    required this.episodes,
    required this.currentEpisodeId,
    required this.imageApi,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = _isCompact(context);

    return SizedBox(
      height: isMobile ? 150 : 180,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: episodes.length,
        separatorBuilder: (_, __) => SizedBox(width: isMobile ? 8 : 12),
        itemBuilder: (context, index) {
          final ep = episodes[index];
          final isCurrent = ep.id == currentEpisodeId;
          final epNum = ep.indexNumber;
          final runtime = ep.runtime;
          final runtimeText =
              runtime != null
                  ? (runtime.inHours > 0
                      ? '${runtime.inHours}h ${runtime.inMinutes.remainder(60)}m'
                      : '${runtime.inMinutes}m')
                  : null;

          return GestureDetector(
            onTap:
                () => context.push(
                  Destinations.item(ep.id, serverId: ep.serverId),
                ),
            child: Container(
              width: isMobile ? 180.0 : 220.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border:
                    isCurrent
                        ? Border.all(color: const Color(0xFF00A4DC), width: 2)
                        : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: isMobile ? 100 : 124,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (ep.primaryImageTag != null)
                          CachedNetworkImage(
                            imageUrl: imageApi.getPrimaryImageUrl(
                              ep.id,
                              maxHeight: 250,
                              tag: ep.primaryImageTag,
                            ),
                            fit: BoxFit.cover,
                            errorWidget:
                                (_, __, ___) => Container(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  child: const Icon(
                                    Icons.movie,
                                    color: Colors.white24,
                                    size: 32,
                                  ),
                                ),
                          )
                        else
                          Container(
                            color: Colors.white.withValues(alpha: 0.05),
                            child: const Icon(
                              Icons.movie,
                              color: Colors.white24,
                              size: 32,
                            ),
                          ),
                        if ((ep.playedPercentage ?? 0) > 0)
                          _EpisodeProgressBar(percentage: ep.playedPercentage!),
                        if (ep.isPlayed && (ep.playedPercentage ?? 0) == 0)
                          const Positioned(
                            top: 6,
                            right: 6,
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                    child: Row(
                      children: [
                        if (epNum != null)
                          Text(
                            'E$epNum',
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (epNum != null) const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            ep.name,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (runtimeText != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            runtimeText,
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NextUpCard extends StatefulWidget {
  final AggregatedItem episode;
  final ImageApi imageApi;

  const _NextUpCard({required this.episode, required this.imageApi});

  @override
  State<_NextUpCard> createState() => _NextUpCardState();
}

class _NextUpCardState extends State<_NextUpCard> with FocusStateMixin {

  @override
  Widget build(BuildContext context) {
    final episode = widget.episode;
    final s = episode.parentIndexNumber;
    final e = episode.indexNumber;
    final label = s != null && e != null ? 'S${s}E$e' : null;
    final subtitle = [if (label != null) label, episode.name].join(' - ');

    final isMobile = _isCompact(context);
    final focusColor =
        Color(GetIt.instance<UserPreferences>().get(UserPreferences.focusColor).colorValue);
    final cardExpansion =
      GetIt.instance<UserPreferences>().get(UserPreferences.cardFocusExpansion);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: Focus(
        onFocusChange: (focused) => setFocused(focused),
        child: GestureDetector(
          onTap:
              () => context.push(
                Destinations.item(episode.id, serverId: episode.serverId),
              ),
          child: AnimatedScale(
            scale: cardExpansion && showFocusBorder ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              height: isMobile ? 100.0 : 120.0,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: showFocusBorder
                    ? Border.all(color: focusColor, width: 1.5)
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  SizedBox(
                    width: isMobile ? 178.0 : 213.0,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (episode.primaryImageTag != null)
                          CachedNetworkImage(
                            imageUrl: widget.imageApi.getPrimaryImageUrl(
                              episode.id,
                              maxHeight: 240,
                              tag: episode.primaryImageTag,
                            ),
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        if ((episode.playedPercentage ?? 0) > 0)
                          _EpisodeProgressBar(percentage: episode.playedPercentage!),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (episode.overview != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            episode.overview!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.play_circle_outline,
                    color: Colors.white54,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodeCard extends StatefulWidget {
  final AggregatedItem episode;
  final ImageApi imageApi;

  const _EpisodeCard({required this.episode, required this.imageApi});

  @override
  State<_EpisodeCard> createState() => _EpisodeCardState();
}

class _EpisodeCardState extends State<_EpisodeCard> with FocusStateMixin {

  @override
  Widget build(BuildContext context) {
    final episode = widget.episode;
    final epNum = episode.indexNumber;
    final runtime = episode.runtime;
    final runtimeText =
        runtime != null
            ? (runtime.inHours > 0
                ? '${runtime.inHours}h ${runtime.inMinutes.remainder(60)}m'
                : '${runtime.inMinutes}m')
            : null;

    final focusColor =
        Color(GetIt.instance<UserPreferences>().get(UserPreferences.focusColor).colorValue);
    final cardExpansion =
      GetIt.instance<UserPreferences>().get(UserPreferences.cardFocusExpansion);
    final isMobile = _isCompact(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: Focus(
        onFocusChange: (focused) => setFocused(focused),
        child: GestureDetector(
          onTap:
              () => context.push(
                Destinations.item(episode.id, serverId: episode.serverId),
              ),
          child: AnimatedScale(
            scale: cardExpansion && showFocusBorder ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              height: isMobile ? 90.0 : 110.0,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border:
                    showFocusBorder
                        ? Border.all(color: focusColor, width: 1.5)
                        : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  SizedBox(
                    width: isMobile ? 160.0 : 196.0,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (episode.primaryImageTag != null)
                          CachedNetworkImage(
                            imageUrl: widget.imageApi.getPrimaryImageUrl(
                              episode.id,
                              maxHeight: 220,
                              tag: episode.primaryImageTag,
                            ),
                            fit: BoxFit.cover,
                            errorWidget:
                                (_, __, ___) => Container(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  child: const Icon(
                                    Icons.movie,
                                    color: Colors.white24,
                                    size: 32,
                                  ),
                                ),
                          )
                        else
                          Container(
                            color: Colors.white.withValues(alpha: 0.05),
                            child: const Icon(
                              Icons.movie,
                              color: Colors.white24,
                              size: 32,
                            ),
                          ),
                        if ((episode.playedPercentage ?? 0) > 0)
                          _EpisodeProgressBar(percentage: episode.playedPercentage!),
                        if (episode.isPlayed)
                          const Positioned(
                            top: 6,
                            right: 6,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFF00A4DC),
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(3),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          [
                            if (epNum != null) 'Episode $epNum',
                            episode.name,
                          ].join(' - '),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (runtimeText != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            runtimeText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                        if (episode.overview != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            episode.overview!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PersonHeader extends StatelessWidget {
  final AggregatedItem item;
  final ImageApi imageApi;

  const _PersonHeader({required this.item, required this.imageApi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = _isCompact(context);
    final safeTop = MediaQuery.of(context).padding.top;
    String? imageUrl;
    if (item.primaryImageTag != null) {
      imageUrl = imageApi.getPrimaryImageUrl(
        item.id,
        maxHeight: 400,
        tag: item.primaryImageTag,
      );
    }

    final avatarRadius = isMobile ? 60.0 : 80.0;
    final avatar = CircleAvatar(
      radius: avatarRadius,
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      backgroundImage:
          imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
      child:
          imageUrl == null
              ? Icon(
                Icons.person,
                color: Colors.white54,
                size: isMobile ? 48 : 64,
              )
              : null,
    );

    final info = Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (!isMobile) const SizedBox(height: 16),
        Text(
          item.name,
          style: (isMobile
                  ? theme.textTheme.headlineSmall
                  : theme.textTheme.headlineLarge)
              ?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: _textShadows,
              ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 8),
        _PersonDates(item: item),
        if (item.productionLocations.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              item.productionLocations.first,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                shadows: _textShadows,
              ),
            ),
          ),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(top: safeTop + (isMobile ? 60 : 80)),
      child:
          isMobile
              ? Column(children: [avatar, const SizedBox(height: 16), info])
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatar,
                  const SizedBox(width: 32),
                  Expanded(child: info),
                ],
              ),
    );
  }
}

class _PersonDates extends StatelessWidget {
  final AggregatedItem item;

  const _PersonDates({required this.item});

  @override
  Widget build(BuildContext context) {
    final birth = item.premiereDate;
    final death = item.endDate;
    if (birth == null && death == null) return const SizedBox.shrink();

    final parts = <String>[];
    if (birth != null) {
      parts.add('Born ${_formatDate(birth)}');
    }
    if (death != null) {
      parts.add('Died ${_formatDate(death)}');
    } else if (birth != null) {
      final age = _calculateAge(birth);
      if (age > 0) parts.add('Age $age');
    }

    return Text(
      parts.join('  \u2022  '),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Colors.white.withValues(alpha: 0.7),
        shadows: _textShadows,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  int _calculateAge(DateTime birth) {
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }
}

class _ExpandableBiography extends StatefulWidget {
  final String text;

  const _ExpandableBiography({required this.text});

  @override
  State<_ExpandableBiography> createState() => _ExpandableBiographyState();
}

class _ExpandableBiographyState extends State<_ExpandableBiography> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: Colors.white.withValues(alpha: 0.9),
      shadows: _textShadows,
      height: 1.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Text(
            widget.text,
            style: style,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(widget.text, style: style),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Show Less' : 'Read More',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF00A4DC),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilmographyRow extends StatelessWidget {
  final List<AggregatedItem> items;
  final ImageApi imageApi;
  final UserPreferences prefs;
  final ScrollController? scrollController;

  const _FilmographyRow({
    required this.items,
    required this.imageApi,
    required this.prefs,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final watchedBehavior = prefs.get(UserPreferences.watchedIndicatorBehavior);
    final cardExpansion = prefs.get(UserPreferences.cardFocusExpansion);
    final isMobile = _isCompact(context);
    final cardWidth = isMobile ? 120.0 : 150.0;

    return SizedBox(
      height: isMobile ? 220 : 280,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: isMobile ? 8 : 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final year = item.productionYear;

          return MediaCard(
            title: item.name,
            subtitle: year?.toString(),
            imageUrl:
                item.primaryImageTag != null
                    ? imageApi.getPrimaryImageUrl(
                      item.id,
                      maxHeight: isMobile ? 300 : 400,
                      tag: item.primaryImageTag,
                    )
                    : null,
            width: cardWidth,
            aspectRatio: 2 / 3,
            focusColor: Color(prefs.get(UserPreferences.focusColor).colorValue),
            cardFocusExpansion: cardExpansion,
            isFavorite: item.isFavorite,
            isPlayed: item.isPlayed,
            playedPercentage: item.playedPercentage,
            watchedBehavior: watchedBehavior,
            itemType: item.type,
            onTap:
                () => context.push(
                  Destinations.item(item.id, serverId: item.serverId),
                ),
          );
        },
      ),
    );
  }
}

class _ArtistHeader extends StatelessWidget {
  final AggregatedItem item;
  final ImageApi imageApi;

  const _ArtistHeader({required this.item, required this.imageApi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = _isCompact(context);
    final safeTop = MediaQuery.of(context).padding.top;
    String? imageUrl;
    if (item.primaryImageTag != null) {
      imageUrl = imageApi.getPrimaryImageUrl(
        item.id,
        maxHeight: 400,
        tag: item.primaryImageTag,
      );
    }

    final avatarRadius = isMobile ? 60.0 : 80.0;
    final avatar = CircleAvatar(
      radius: avatarRadius,
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      backgroundImage:
          imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
      child:
          imageUrl == null
              ? Icon(
                Icons.music_note,
                color: Colors.white54,
                size: isMobile ? 48 : 64,
              )
              : null,
    );

    final info = Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (!isMobile) const SizedBox(height: 16),
        Text(
          item.name,
          style: (isMobile
                  ? theme.textTheme.headlineSmall
                  : theme.textTheme.headlineLarge)
              ?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: _textShadows,
              ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        if (item.genres.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            item.genres.join(' \u2022 '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              shadows: _textShadows,
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: EdgeInsets.only(top: safeTop + (isMobile ? 60 : 80)),
      child:
          isMobile
              ? Column(children: [avatar, const SizedBox(height: 16), info])
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatar,
                  const SizedBox(width: 32),
                  Expanded(child: info),
                ],
              ),
    );
  }
}

class _AlbumHeader extends StatelessWidget {
  final AggregatedItem item;
  final ImageApi imageApi;
  final VoidCallback? onRenameRequested;

  const _AlbumHeader({
    required this.item,
    required this.imageApi,
    this.onRenameRequested,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = _isCompact(context);
    final safeTop = MediaQuery.of(context).padding.top;
    final albumSize = isMobile ? 150.0 : 200.0;

    final albumArt = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child:
          item.primaryImageTag != null
              ? CachedNetworkImage(
                imageUrl: imageApi.getPrimaryImageUrl(
                  item.id,
                  maxHeight: 400,
                  tag: item.primaryImageTag,
                ),
                width: albumSize,
                height: albumSize,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _albumPlaceholder(albumSize),
              )
              : _albumPlaceholder(albumSize),
    );

    final info = Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (!isMobile) const SizedBox(height: 16),
        GestureDetector(
          onTap: onRenameRequested,
          child: Text(
            item.name,
            style: (isMobile
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.headlineLarge)
                ?.copyWith(
                  color:
                      onRenameRequested != null
                          ? const Color(0xFF00A4DC)
                          : Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: _textShadows,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: isMobile ? TextAlign.center : TextAlign.start,
          ),
        ),
        if (item.albumArtist != null) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              final artistId =
                  item.albumArtists.isNotEmpty
                      ? item.albumArtists.first['Id'] as String?
                      : null;
              if (artistId != null) {
                context.push(
                  Destinations.item(artistId, serverId: item.serverId),
                );
              }
            },
            child: Text(
              item.albumArtist!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF00A4DC),
                shadows: _textShadows,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        _AlbumMeta(item: item),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(top: safeTop + (isMobile ? 60 : 80)),
      child:
          isMobile
              ? Column(children: [albumArt, const SizedBox(height: 16), info])
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  albumArt,
                  const SizedBox(width: 32),
                  Expanded(child: info),
                ],
              ),
    );
  }

  Widget _albumPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.white.withValues(alpha: 0.1),
      child: const Icon(Icons.album, color: Colors.white24, size: 64),
    );
  }
}

class _AlbumMeta extends StatelessWidget {
  final AggregatedItem item;

  const _AlbumMeta({required this.item});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (item.productionYear != null) parts.add(item.productionYear.toString());
    final songCount = item.childCount ?? item.recursiveItemCount;
    if (songCount != null) {
      parts.add(songCount == 1 ? '1 track' : '$songCount tracks');
    }
    if (item.genres.isNotEmpty) {
      parts.add(item.genres.take(2).join(', '));
    }
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' \u2022 '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Colors.white.withValues(alpha: 0.7),
        shadows: _textShadows,
      ),
    );
  }
}

class _AlbumActions extends StatelessWidget {
  final AggregatedItem item;
  final List<AggregatedItem> tracks;
  final bool showAddToPlaylist;
  final VoidCallback? onDownloadAll;
  final VoidCallback? onDeleteDownloaded;
  final VoidCallback? onDeletePlaylist;

  const _AlbumActions({
    required this.item,
    required this.tracks,
    this.showAddToPlaylist = true,
    this.onDownloadAll,
    this.onDeleteDownloaded,
    this.onDeletePlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final manager = GetIt.instance<PlaybackManager>();
    final offlineRepo = GetIt.instance<OfflineRepository>();
    final trackIds = tracks.map((track) => track.id).toSet();
    if (trackIds.isEmpty) {
      return _buildActions(context, manager, false);
    }

    return StreamBuilder<List<DownloadedItem>>(
      stream: offlineRepo.watchItems(),
      builder: (context, snapshot) {
        final hasDownloadedTracks =
            snapshot.data?.any(
              (row) =>
                  row.downloadStatus == 2 &&
                  row.localFilePath != null &&
                  trackIds.contains(row.itemId),
            ) ??
            false;
        return _buildActions(context, manager, hasDownloadedTracks);
      },
    );
  }

  Widget _buildActions(
    BuildContext context,
    PlaybackManager manager,
    bool hasDownloadedTracks,
  ) {
    return Center(
      child: Wrap(
        spacing: 8,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          _DetailActionButton(
            label: 'Play',
            icon: Icons.play_arrow,
            onPressed: () {
              if (tracks.isEmpty) return;
              manager.playItems(tracks);
              context.push(Destinations.audioPlayer);
            },
          ),
          _DetailActionButton(
            label: 'Shuffle',
            icon: Icons.shuffle,
            onPressed: () {
              if (tracks.isEmpty) return;
              final shuffled = List<AggregatedItem>.from(tracks)..shuffle();
              manager.playItems(shuffled);
              context.push(Destinations.audioPlayer);
            },
          ),
          if (onDownloadAll != null)
            _DetailActionButton(
              label: 'Download All',
              icon: Icons.download,
              onPressed: onDownloadAll!,
            ),
          if (onDeleteDownloaded != null && hasDownloadedTracks)
            _DetailActionButton(
              label: 'Delete Downloaded',
              icon: Icons.delete_sweep,
              onPressed: onDeleteDownloaded!,
            ),
          if (onDeletePlaylist != null)
            _DetailActionButton(
              label: 'Delete',
              icon: Icons.delete_outline,
              onPressed: onDeletePlaylist!,
            ),
          if (showAddToPlaylist)
            _DetailActionButton(
              label: 'Playlist',
              icon: Icons.playlist_add,
              onPressed:
                  () => AddToPlaylistDialog.show(context, itemIds: [item.id]),
            ),
        ],
      ),
    );
  }
}

class _AlbumsRow extends StatelessWidget {
  final List<AggregatedItem> albums;
  final ImageApi imageApi;
  final UserPreferences prefs;
  final ScrollController? scrollController;

  const _AlbumsRow({
    required this.albums,
    required this.imageApi,
    required this.prefs,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final watchedBehavior = prefs.get(UserPreferences.watchedIndicatorBehavior);
    final cardExpansion = prefs.get(UserPreferences.cardFocusExpansion);
    final isMobile = _isCompact(context);
    final cardWidth = isMobile ? 120.0 : 150.0;

    return SizedBox(
      height: isMobile ? 180 : 220,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: albums.length,
        separatorBuilder: (_, __) => SizedBox(width: isMobile ? 8 : 12),
        itemBuilder: (context, index) {
          final album = albums[index];
          return MediaCard(
            title: album.name,
            subtitle: album.productionYear?.toString(),
            imageUrl:
                album.primaryImageTag != null
                    ? imageApi.getPrimaryImageUrl(
                      album.id,
                      maxHeight: isMobile ? 240 : 300,
                      tag: album.primaryImageTag,
                    )
                    : null,
            width: cardWidth,
            aspectRatio: 1.0,
            focusColor: Color(prefs.get(UserPreferences.focusColor).colorValue),
            cardFocusExpansion: cardExpansion,
            watchedBehavior: watchedBehavior,
            itemType: album.type,
            onTap:
                () => context.push(
                  Destinations.item(album.id, serverId: album.serverId),
                ),
          );
        },
      ),
    );
  }
}

class _TrackList extends StatelessWidget {
  final List<AggregatedItem> tracks;
  final ValueChanged<int> onPlayTrack;
  final bool reorderable;
  final ReorderCallback? onReorder;
  final ValueChanged<AggregatedItem>? onRemoveFromPlaylist;
  final ValueChanged<int>? onMoveUp;
  final ValueChanged<int>? onMoveDown;

  const _TrackList({
    required this.tracks,
    required this.onPlayTrack,
    this.reorderable = false,
    this.onReorder,
    this.onRemoveFromPlaylist,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    if (reorderable && onReorder != null) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: tracks.length,
        onReorder: onReorder!,
        itemBuilder: (context, index) {
          final track = tracks[index];
          final keyId = track.rawData['PlaylistItemId'] as String? ?? track.id;
          return _TrackTile(
            key: ValueKey('playlist-track-$keyId'),
            track: track,
            index: index + 1,
            totalCount: tracks.length,
            currentIndex: index,
            reorderable: true,
            reorderIndex: index,
            onTap: () => onPlayTrack(index),
            onRemoveFromPlaylist: onRemoveFromPlaylist,
            onMoveUp: onMoveUp,
            onMoveDown: onMoveDown,
          );
        },
      );
    }

    return Column(
      children: List.generate(tracks.length, (index) {
        return _TrackTile(
          track: tracks[index],
          index: index + 1,
          totalCount: tracks.length,
          currentIndex: index,
          reorderable: false,
          reorderIndex: index,
          onTap: () => onPlayTrack(index),
          onRemoveFromPlaylist: onRemoveFromPlaylist,
          onMoveUp: onMoveUp,
          onMoveDown: onMoveDown,
        );
      }),
    );
  }
}

class _TrackTile extends StatefulWidget {
  final AggregatedItem track;
  final int index;
  final int currentIndex;
  final int totalCount;
  final bool reorderable;
  final int reorderIndex;
  final VoidCallback onTap;
  final ValueChanged<AggregatedItem>? onRemoveFromPlaylist;
  final ValueChanged<int>? onMoveUp;
  final ValueChanged<int>? onMoveDown;

  const _TrackTile({
    super.key,
    required this.track,
    required this.index,
    required this.currentIndex,
    required this.totalCount,
    required this.reorderable,
    required this.reorderIndex,
    required this.onTap,
    this.onRemoveFromPlaylist,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  State<_TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<_TrackTile> with FocusStateMixin {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final runtime = widget.track.runtime;
    final runtimeText =
        runtime != null
            ? '${runtime.inMinutes}:${(runtime.inSeconds % 60).toString().padLeft(2, '0')}'
            : null;
    final trackNumber = widget.track.indexNumber ?? widget.index;
    final activeColor = focusColor;
    final baseBackground = widget.index.isOdd
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.transparent;
    final activeBackground = activeColor.withValues(alpha: 0.14);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setHovered(true),
      onExit: (_) => setHovered(false),
      child: Focus(
        onFocusChange: (hasFocus) => setFocused(hasFocus),
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.reorderable ? null : () => _showTrackActions(context),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 56,
            decoration: BoxDecoration(
              color: showFocusBorder ? activeBackground : baseBackground,
              borderRadius: BorderRadius.circular(4),
              border: showFocusBorder
                  ? Border.all(color: activeColor.withValues(alpha: 0.85), width: 1.25)
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      trackNumber.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: showFocusBorder
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.track.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: showFocusBorder ? FontWeight.w600 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      () {
                        final artistText = widget.track.artists.isNotEmpty
                            ? widget.track.artists.join(', ')
                            : widget.track.albumArtist ?? '';
                        if (artistText.isNotEmpty) {
                          return Text(
                            artistText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: showFocusBorder
                                  ? Colors.white.withValues(alpha: 0.82)
                                  : Colors.white.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                        return const SizedBox.shrink();
                      }(),
                    ],
                  ),
                ),
                if (runtimeText != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      runtimeText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: showFocusBorder
                            ? Colors.white.withValues(alpha: 0.82)
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                if (widget.reorderable)
                  ReorderableDragStartListener(
                    index: widget.reorderIndex,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.drag_indicator,
                        color: showFocusBorder ? Colors.white70 : Colors.white38,
                        size: 18,
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: widget.onTap,
                  icon: Icon(
                    Icons.play_arrow,
                    color: showFocusBorder ? Colors.white : Colors.white54,
                    size: 22,
                  ),
                  splashRadius: 20,
                ),
                IconButton(
                  onPressed: () => _showTrackActions(context),
                  icon: Icon(
                    Icons.more_vert,
                    color: showFocusBorder ? Colors.white : Colors.white54,
                    size: 20,
                  ),
                  splashRadius: 20,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTrackActions(BuildContext context) {
    final manager = GetIt.instance<PlaybackManager>();
    TrackActionDialog.show(
      context,
      track: widget.track,
      onPlay: widget.onTap,
      onPlayNext: () => manager.queueService.insertNext(widget.track),
      onAddToQueue: () => manager.queueService.addToQueue(widget.track),
      onAddToPlaylist:
          () => AddToPlaylistDialog.show(context, itemIds: [widget.track.id]),
      onRemoveFromPlaylist:
          widget.onRemoveFromPlaylist != null
              ? () => widget.onRemoveFromPlaylist!(widget.track)
              : null,
      onMoveUp:
          widget.reorderable && widget.onMoveUp != null && widget.currentIndex > 0
              ? () => widget.onMoveUp!(widget.currentIndex)
              : null,
      onMoveDown:
          widget.reorderable &&
                  widget.onMoveDown != null &&
                  widget.currentIndex < widget.totalCount - 1
              ? () => widget.onMoveDown!(widget.currentIndex)
              : null,
      onToggleFavorite: () {
        GetIt.instance<ItemMutationRepository>().setFavorite(
          widget.track.id,
          isFavorite: !widget.track.isFavorite,
        );
      },
    );
  }
}
