import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/repositories/item_mutation_repository.dart';
import '../../../data/repositories/mdblist_repository.dart';
import '../../../data/services/background_service.dart';
import '../../../data/services/theme_music_service.dart';
import '../../../data/viewmodels/item_detail_view_model.dart';
import '../../../preference/user_preferences.dart';
import '../../navigation/destinations.dart';
import '../../widgets/add_to_playlist_dialog.dart';
import '../../widgets/logo_view.dart';
import '../../widgets/media_card.dart';
import '../../widgets/rating_display.dart';
import '../../widgets/track_action_dialog.dart';
import '../../widgets/track_selector_dialog.dart';
import '../../../util/platform_detection.dart';

const _textShadows = [Shadow(blurRadius: 4, color: Colors.black54)];
const _kCompactBreakpoint = 600.0;

bool _isCompact(BuildContext context) =>
    PlatformDetection.isMobile || MediaQuery.sizeOf(context).width < _kCompactBreakpoint;

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late final ItemDetailViewModel _viewModel;
  final _backgroundService = GetIt.instance<BackgroundService>();
  final _themeMusicService = GetIt.instance<ThemeMusicService>();
  final _prefs = GetIt.instance<UserPreferences>();
  String? _backdropUrl;
  bool _themeMusicStarted = false;

  @override
  void initState() {
    super.initState();
    _viewModel = ItemDetailViewModel(
      itemId: widget.itemId,
      client: GetIt.instance<MediaServerClient>(),
      mutations: GetIt.instance<ItemMutationRepository>(),
      mdbListRepository: GetIt.instance<MdbListRepository>(),
    );
    _viewModel.addListener(_onChanged);
    _viewModel.load();

    _backdropUrl = _backgroundService.currentUrl;
  }

  @override
  void dispose() {
    _themeMusicService.fadeOutAndStop();
    _backgroundService.clearBackgrounds();
    _viewModel.removeListener(_onChanged);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBody(context),
          const _BackButton(),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return switch (_viewModel.state) {
      ItemDetailState.loading => const Center(child: CircularProgressIndicator()),
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
        ),
    };
  }
}

class _DetailContent extends StatelessWidget {
  final ItemDetailViewModel viewModel;
  final UserPreferences prefs;
  final String? backdropUrl;

  const _DetailContent({
    required this.viewModel,
    required this.prefs,
    this.backdropUrl,
  });

  @override
  Widget build(BuildContext context) {
    final item = viewModel.item!;
    final blurAmount = prefs.get(UserPreferences.detailsBackgroundBlurAmount).toDouble();
    final backdropEnabled = prefs.get(UserPreferences.backdropEnabled);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (backdropEnabled)
          _Backdrop(url: backdropUrl, blurAmount: blurAmount),
        const _GradientScrim(),
        CustomScrollView(
          slivers: [
            if (item.type != 'Person' && item.type != 'MusicArtist' &&
                item.type != 'MusicAlbum' && item.type != 'Playlist')
              SliverToBoxAdapter(child: _HeaderSection(viewModel: viewModel, prefs: prefs)),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: _isCompact(context) ? 16 : 48,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  _buildContentForType(item),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildContentForType(AggregatedItem item) {
    return switch (item.type) {
      'Series' => _buildSeriesContent(item),
      'Season' => _buildSeasonContent(item),
      'Episode' => _buildEpisodeContent(item),
      'Person' => _buildPersonContent(item),
      'MusicArtist' => _buildArtistContent(item),
      'MusicAlbum' || 'Playlist' => _buildAlbumContent(item),
      'BoxSet' => _buildBoxSetContent(item),
      _ => _buildMovieContent(item),
    };
  }

  List<Widget> _buildMovieContent(AggregatedItem item) {
    return [
      _ActionButtons(viewModel: viewModel),
      if (_hasMetadata(item)) ...[
        const SizedBox(height: 24),
        _MetadataSection(viewModel: viewModel),
      ],
      if (viewModel.actors.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'Cast & Crew'),
        const SizedBox(height: 12),
        _CastRow(people: viewModel.actors, imageApi: viewModel.imageApi),
      ],
      if (viewModel.similar.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'More Like This'),
        const SizedBox(height: 12),
        _SimilarRow(items: viewModel.similar, imageApi: viewModel.imageApi, prefs: prefs),
      ],
      const SizedBox(height: 48),
    ];
  }

  List<Widget> _buildSeriesContent(AggregatedItem item) {
    return [
      _ActionButtons(viewModel: viewModel),
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
        _SectionHeader(title: 'Seasons'),
        const SizedBox(height: 12),
        _SeasonsRow(seasons: viewModel.seasons, imageApi: viewModel.imageApi, prefs: prefs),
      ],
      if (viewModel.actors.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'Cast & Crew'),
        const SizedBox(height: 12),
        _CastRow(people: viewModel.actors, imageApi: viewModel.imageApi),
      ],
      if (viewModel.similar.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'More Like This'),
        const SizedBox(height: 12),
        _SimilarRow(items: viewModel.similar, imageApi: viewModel.imageApi, prefs: prefs),
      ],
      const SizedBox(height: 48),
    ];
  }

  List<Widget> _buildSeasonContent(AggregatedItem item) {
    return [
      _ActionButtons(viewModel: viewModel),
      if (viewModel.episodes.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'Episodes'),
        const SizedBox(height: 12),
        ...viewModel.episodes.map((ep) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _EpisodeCard(episode: ep, imageApi: viewModel.imageApi),
        )),
      ],
      const SizedBox(height: 48),
    ];
  }

  List<Widget> _buildEpisodeContent(AggregatedItem item) {
    return [
      _ActionButtons(viewModel: viewModel),
      if (_hasMetadata(item)) ...[
        const SizedBox(height: 24),
        _MetadataSection(viewModel: viewModel),
      ],
      if (viewModel.episodes.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'Episodes'),
        const SizedBox(height: 12),
        _EpisodesRow(
          episodes: viewModel.episodes,
          currentEpisodeId: item.id,
          imageApi: viewModel.imageApi,
        ),
      ],
      if (viewModel.actors.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'Cast & Crew'),
        const SizedBox(height: 12),
        _CastRow(people: viewModel.actors, imageApi: viewModel.imageApi),
      ],
      if (viewModel.similar.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'More Like This'),
        const SizedBox(height: 12),
        _SimilarRow(items: viewModel.similar, imageApi: viewModel.imageApi, prefs: prefs),
      ],
      const SizedBox(height: 48),
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
        _SectionHeader(title: 'Movies'),
        const SizedBox(height: 12),
        _FilmographyRow(items: movies, imageApi: viewModel.imageApi, prefs: prefs),
      ],
      if (series.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'Series'),
        const SizedBox(height: 12),
        _FilmographyRow(items: series, imageApi: viewModel.imageApi, prefs: prefs),
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
        _SectionHeader(title: 'Discography'),
        const SizedBox(height: 12),
        _AlbumsRow(albums: viewModel.albums, imageApi: viewModel.imageApi, prefs: prefs),
      ],
      if (viewModel.similar.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'Similar Artists'),
        const SizedBox(height: 12),
        _SimilarRow(items: viewModel.similar, imageApi: viewModel.imageApi, prefs: prefs),
      ],
      const SizedBox(height: 48),
    ];
  }

  List<Widget> _buildAlbumContent(AggregatedItem item) {
    return [
      _AlbumHeader(item: item, imageApi: viewModel.imageApi),
      if (viewModel.tracks.isNotEmpty) ...[
        const SizedBox(height: 24),
        _TrackList(tracks: viewModel.tracks),
      ],
      const SizedBox(height: 48),
    ];
  }

  List<Widget> _buildBoxSetContent(AggregatedItem item) {
    final movies = viewModel.collectionItems
        .where((i) => i.type == 'Movie')
        .toList();
    final series = viewModel.collectionItems
        .where((i) => i.type == 'Series')
        .toList();
    final other = viewModel.collectionItems
        .where((i) => i.type != 'Movie' && i.type != 'Series')
        .toList();

    return [
      if (_hasMetadata(item)) ...[
        const SizedBox(height: 24),
        _MetadataSection(viewModel: viewModel),
      ],
      if (movies.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'Movies'),
        const SizedBox(height: 12),
        _SimilarRow(items: movies, imageApi: viewModel.imageApi, prefs: prefs),
      ],
      if (series.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'Series'),
        const SizedBox(height: 12),
        _SimilarRow(items: series, imageApi: viewModel.imageApi, prefs: prefs),
      ],
      if (other.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'Other'),
        const SizedBox(height: 12),
        _SimilarRow(items: other, imageApi: viewModel.imageApi, prefs: prefs),
      ],
      if (viewModel.actors.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'Cast & Crew'),
        const SizedBox(height: 12),
        _CastRow(people: viewModel.actors, imageApi: viewModel.imageApi),
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
      child: url != null
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
            colors: [
              Color(0xCC000000),
              Color(0x66000000),
              Color(0xCC000000),
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    final isMobile = _isCompact(context);
    final top = MediaQuery.of(context).padding.top;

    return Positioned(
      top: top + (isMobile ? 8 : 16),
      left: isMobile ? 8 : 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.pop(),
          customBorder: const CircleBorder(),
          child: Container(
            width: isMobile ? 36 : 40,
            height: isMobile ? 36 : 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: isMobile ? 18 : 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final ItemDetailViewModel viewModel;
  final UserPreferences prefs;

  const _HeaderSection({required this.viewModel, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final item = viewModel.item!;
    final imageApi = viewModel.imageApi;
    final isEpisode = item.type == 'Episode';
    final isMobile = _isCompact(context);

    final infoColumn = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            child: isMobile
                ? Center(
                    child: LogoView(
                      imageUrl: imageApi.getLogoImageUrl(item.id, tag: item.logoImageTag),
                      maxHeight: 56,
                      maxWidth: 240,
                    ),
                  )
                : LogoView(
                    imageUrl: imageApi.getLogoImageUrl(item.id, tag: item.logoImageTag),
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
        _MetadataRow(item: item),
        if (viewModel.ratings.isNotEmpty ||
            item.communityRating != null ||
            item.criticRating != null) ...[
          const SizedBox(height: 8),
          RatingsRow(
            ratings: viewModel.ratings,
            communityRating: item.communityRating,
            criticRating: item.criticRating,
            enableAdditionalRatings: prefs.get(UserPreferences.enableAdditionalRatings),
            enabledRatings: prefs.get(UserPreferences.enabledRatings),
            blockedRatings: prefs.get(UserPreferences.blockedRatings),
            showLabels: prefs.get(UserPreferences.showRatingLabels),
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

    final posterWidget = isEpisode
        ? _EpisodeThumbnail(item: item, imageApi: imageApi)
        : _PosterImage(item: item, imageApi: imageApi);

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 60, 16, 12),
        child: Column(
          children: [
            posterWidget,
            const SizedBox(height: 16),
            infoColumn,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 80, 48, 16),
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

class _PosterImage extends StatelessWidget {
  final AggregatedItem item;
  final ImageApi imageApi;

  const _PosterImage({required this.item, required this.imageApi});

  @override
  Widget build(BuildContext context) {
    final isMobile = _isCompact(context);
    final w = isMobile ? 120.0 : 165.0;
    final h = isMobile ? 180.0 : 248.0;

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
                child: const Icon(Icons.favorite, color: Color(0xFFFF4757), size: 16),
              ),
            ),
          if (item.isPlayed)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 16),
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
                  minHeight: 4,
                  backgroundColor: Colors.black38,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00A4DC)),
                ),
              ),
            ),
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
    final isMobile = _isCompact(context);
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
                child: const Icon(Icons.favorite, color: Color(0xFFFF4757), size: 14),
              ),
            ),
          if (item.isPlayed)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 14),
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
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00A4DC)),
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

  const _MetadataRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final parts = <Widget>[];
    final theme = Theme.of(context);

    if (item.productionYear != null) {
      parts.add(_text(theme, item.productionYear.toString()));
    }

    if (item.officialRating != null) {
      parts.add(_badge(theme, item.officialRating!));
    }

    final runtime = item.runtime;
    if (runtime != null && item.type != 'Series') {
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

    final use24 = GetIt.instance<UserPreferences>().get(UserPreferences.use24HourClock);
    final endsAt = item.endsAt(use24Hour: use24);
    if (endsAt != null && item.type != 'Series') {
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
        separated.add(Text(
          ' \u2022 ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
            shadows: _textShadows,
          ),
        ));
      }
    }

    final badges = <String>[];
    final res = item.videoResolution;
    if (res != null) badges.add(res);
    final hdr = item.hdrType;
    if (hdr != null) badges.add(hdr);
    final vcodec = item.videoCodec?.toUpperCase();
    if (vcodec != null) badges.add(vcodec);
    final acodec = item.audioCodec?.toUpperCase();
    if (acodec != null) badges.add(acodec);
    final layout = item.channelLayout;
    if (layout != null) badges.add(layout);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 2,
          runSpacing: 4,
          children: [
            ...separated,
            if (!_isCompact(context) && badges.isNotEmpty) ...[
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
        if (_isCompact(context) && badges.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
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

class _ActionButtons extends StatelessWidget {
  final ItemDetailViewModel viewModel;

  const _ActionButtons({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final item = viewModel.item!;
    final hasProgress = (item.playedPercentage ?? 0) > 0;
    final audioStreams = item.mediaStreams
        .where((s) => s['Type'] == 'Audio')
        .toList();
    final subtitleStreams = item.mediaStreams
        .where((s) => s['Type'] == 'Subtitle')
        .toList();

    return Center(
      child: Wrap(
        spacing: 8,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          if (hasProgress)
            _DetailActionButton(
              label: 'Resume',
              icon: Icons.play_arrow,
              onPressed: () {},
            ),
          _DetailActionButton(
            label: hasProgress ? 'Restart' : 'Play',
            icon: hasProgress ? Icons.restart_alt : Icons.play_arrow,
            onPressed: () {},
          ),
          if (audioStreams.length > 1)
            _DetailActionButton(
              label: 'Audio',
              icon: Icons.audiotrack,
              onPressed: () => _showAudioSelector(context, audioStreams),
            ),
          if (subtitleStreams.isNotEmpty)
            _DetailActionButton(
              label: 'Subtitles',
              icon: Icons.subtitles,
              onPressed: () => _showSubtitleSelector(context, subtitleStreams),
            ),
          if (item.remoteTrailers.isNotEmpty)
            _DetailActionButton(
              label: 'Trailer',
              icon: Icons.movie_outlined,
              onPressed: () {},
            ),
          _DetailActionButton(
            label: item.isPlayed ? 'Watched' : 'Unwatched',
            icon: Icons.check_circle,
            onPressed: viewModel.togglePlayed,
            isActive: item.isPlayed,
            activeColor: const Color(0xFF2196F3),
          ),
          _DetailActionButton(
            label: item.isFavorite ? 'Favorited' : 'Favorite',
            icon: Icons.favorite,
            onPressed: viewModel.toggleFavorite,
            isActive: item.isFavorite,
            activeColor: const Color(0xFFFF4757),
          ),
          _DetailActionButton(
            label: 'Playlist',
            icon: Icons.playlist_add,
            onPressed: () => AddToPlaylistDialog.show(context, itemIds: [item.id]),
          ),
          if (item.type == 'Episode' && item.seriesId != null)
            _DetailActionButton(
              label: 'Go to Series',
              icon: Icons.tv,
              onPressed: () => context.push(Destinations.item(item.seriesId!)),
            ),
        ],
      ),
    );
  }

  void _showAudioSelector(BuildContext context, List<Map<String, dynamic>> streams) {
    final defaultIdx = streams.indexWhere((s) => s['IsDefault'] == true);
    TrackSelectorDialog.show(
      context,
      title: 'Audio Track',
      options: streams.map((s) {
        final lang = s['DisplayTitle'] as String? ?? s['Language'] as String? ?? 'Unknown';
        final codec = s['Codec'] as String?;
        return TrackOption(label: lang, subtitle: codec?.toUpperCase());
      }).toList(),
      selectedIndex: defaultIdx >= 0 ? defaultIdx : null,
    );
  }

  void _showSubtitleSelector(BuildContext context, List<Map<String, dynamic>> streams) {
    final defaultIdx = streams.indexWhere((s) => s['IsDefault'] == true);
    final options = [
      const TrackOption(label: 'None'),
      ...streams.map((s) {
        final lang = s['DisplayTitle'] as String? ?? s['Language'] as String? ?? 'Unknown';
        final codec = s['Codec'] as String?;
        return TrackOption(label: lang, subtitle: codec?.toUpperCase());
      }),
    ];
    TrackSelectorDialog.show(
      context,
      title: 'Subtitle Track',
      options: options,
      selectedIndex: defaultIdx >= 0 ? defaultIdx + 1 : 0,
    );
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

class _DetailActionButtonState extends State<_DetailActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = _isCompact(context);
    final iconColor = widget.isActive
        ? (widget.activeColor ?? Colors.white)
        : Colors.white;

    final activeColor = widget.isActive ? widget.activeColor : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: SizedBox(
          width: isMobile ? 64 : 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isMobile ? 44 : 52,
                height: isMobile ? 44 : 52,
                decoration: BoxDecoration(
                  color: activeColor != null
                      ? activeColor.withValues(alpha: _hovered ? 0.25 : 0.15)
                      : (_hovered
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.08)),
                  border: Border.all(
                    color: activeColor?.withValues(alpha: 0.4) ??
                        Colors.white.withValues(alpha: 0.15),
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
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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

  const _CastRow({required this.people, required this.imageApi});

  @override
  Widget build(BuildContext context) {
    final isMobile = _isCompact(context);
    final cardWidth = isMobile ? 80.0 : 100.0;
    final avatarRadius = isMobile ? 35.0 : 45.0;

    return SizedBox(
      height: isMobile ? 130 : 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
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
            imageUrl = imageApi.getPrimaryImageUrl(personId, maxHeight: isMobile ? 140 : 200, tag: tag);
          }

          return GestureDetector(
            onTap: personId != null ? () => context.push(Destinations.item(personId)) : null,
            child: SizedBox(
              width: cardWidth,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    backgroundImage: imageUrl != null
                        ? CachedNetworkImageProvider(imageUrl)
                        : null,
                    child: imageUrl == null
                        ? Icon(Icons.person, color: Colors.white54, size: isMobile ? 24 : 32)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 11 : null,
                        ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (role != null)
                    Text(
                      role,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: isMobile ? 10 : 11,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

class _SimilarRow extends StatelessWidget {
  final List<AggregatedItem> items;
  final ImageApi imageApi;
  final UserPreferences prefs;

  const _SimilarRow({required this.items, required this.imageApi, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final watchedBehavior = prefs.get(UserPreferences.watchedIndicatorBehavior);
    final isMobile = _isCompact(context);
    final cardWidth = isMobile ? 120.0 : 150.0;

    return SizedBox(
      height: isMobile ? 210 : 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: isMobile ? 8 : 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final ar = MediaCard.aspectRatioForType(item.type);
          return MediaCard(
            title: item.name,
            imageUrl: item.primaryImageTag != null
                ? imageApi.getPrimaryImageUrl(
                    item.id,
                    maxHeight: isMobile ? 300 : 400,
                    tag: item.primaryImageTag,
                  )
                : null,
            width: cardWidth,
            aspectRatio: ar,
            isFavorite: item.isFavorite,
            isPlayed: item.isPlayed,
            playedPercentage: item.playedPercentage,
            watchedBehavior: watchedBehavior,
            itemType: item.type,
            onTap: () => context.push(Destinations.item(item.id)),
          );
        },
      ),
    );
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
      entries.add(MapEntry('DIRECTOR', viewModel.directors.map((d) => d['Name'] as String).join(', ')));
    }
    if (viewModel.writers.isNotEmpty) {
      entries.add(MapEntry('WRITERS', viewModel.writers.map((w) => w['Name'] as String).join(', ')));
    }
    if (item.studios.isNotEmpty) {
      final studioNames = item.studios.map((s) => s['Name'] as String).toList();
      final display = studioNames.length > 5
          ? '${studioNames.take(5).join(', ')} +${studioNames.length - 5} more'
          : studioNames.join(', ');
      entries.add(MapEntry('STUDIO', display));
    }

    if (entries.isEmpty) return const SizedBox.shrink();

    final isMobile = _isCompact(context);
    final cellPadding = isMobile
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 14);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isMobile
          ? Wrap(
              children: entries.asMap().entries.map((e) {
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
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                                fontSize: 10,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.value,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              entry.key,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.0,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.value,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
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

  const _SeasonsRow({required this.seasons, required this.imageApi, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final watchedBehavior = prefs.get(UserPreferences.watchedIndicatorBehavior);
    final isMobile = _isCompact(context);
    final cardWidth = isMobile ? 120.0 : 150.0;

    return SizedBox(
      height: isMobile ? 220 : 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: seasons.length,
        separatorBuilder: (_, __) => SizedBox(width: isMobile ? 8 : 12),
        itemBuilder: (context, index) {
          final season = seasons[index];
          return MediaCard(
            title: season.name,
            subtitle: _progressText(season),
            imageUrl: season.primaryImageTag != null
                ? imageApi.getPrimaryImageUrl(
                    season.id,
                    maxHeight: isMobile ? 300 : 400,
                    tag: season.primaryImageTag,
                  )
                : null,
            width: cardWidth,
            aspectRatio: 2 / 3,
            isPlayed: season.isPlayed,
            unplayedCount: season.unplayedItemCount,
            watchedBehavior: watchedBehavior,
            itemType: season.type,
            onTap: () => context.push(Destinations.item(season.id)),
          );
        },
      ),
    );
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

  const _EpisodesRow({
    required this.episodes,
    required this.currentEpisodeId,
    required this.imageApi,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = _isCompact(context);

    return SizedBox(
      height: isMobile ? 150 : 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: episodes.length,
        separatorBuilder: (_, __) => SizedBox(width: isMobile ? 8 : 12),
        itemBuilder: (context, index) {
          final ep = episodes[index];
          final isCurrent = ep.id == currentEpisodeId;
          final epNum = ep.indexNumber;
          final runtime = ep.runtime;
          final runtimeText = runtime != null
              ? (runtime.inHours > 0
                  ? '${runtime.inHours}h ${runtime.inMinutes.remainder(60)}m'
                  : '${runtime.inMinutes}m')
              : null;

          return GestureDetector(
            onTap: () => context.push(Destinations.item(ep.id)),
            child: Container(
              width: isMobile ? 180.0 : 220.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: isCurrent
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
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.white.withValues(alpha: 0.05),
                              child: const Icon(Icons.movie, color: Colors.white24, size: 32),
                            ),
                          )
                        else
                          Container(
                            color: Colors.white.withValues(alpha: 0.05),
                            child: const Icon(Icons.movie, color: Colors.white24, size: 32),
                          ),
                        if ((ep.playedPercentage ?? 0) > 0)
                          _EpisodeProgressBar(percentage: ep.playedPercentage!),
                        if (ep.isPlayed && (ep.playedPercentage ?? 0) == 0)
                          const Positioned(
                            top: 6,
                            right: 6,
                            child: Icon(Icons.check_circle, color: Colors.green, size: 18),
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
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        if (epNum != null) const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            ep.name,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

class _NextUpCard extends StatelessWidget {
  final AggregatedItem episode;
  final ImageApi imageApi;

  const _NextUpCard({required this.episode, required this.imageApi});

  @override
  Widget build(BuildContext context) {
    final s = episode.parentIndexNumber;
    final e = episode.indexNumber;
    final label = s != null && e != null ? 'S${s}E$e' : null;
    final subtitle = [if (label != null) label, episode.name].join(' - ');

    final isMobile = _isCompact(context);

    return GestureDetector(
      onTap: () => context.push(Destinations.item(episode.id)),
      child: Container(
        height: isMobile ? 100.0 : 120.0,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
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
                      imageUrl: imageApi.getPrimaryImageUrl(
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
            const Icon(Icons.play_circle_outline, color: Colors.white54, size: 40),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  final AggregatedItem episode;
  final ImageApi imageApi;

  const _EpisodeCard({required this.episode, required this.imageApi});

  @override
  Widget build(BuildContext context) {
    final epNum = episode.indexNumber;
    final runtime = episode.runtime;
    final runtimeText = runtime != null
        ? (runtime.inHours > 0
            ? '${runtime.inHours}h ${runtime.inMinutes.remainder(60)}m'
            : '${runtime.inMinutes}m')
        : null;

    final isMobile = _isCompact(context);

    return GestureDetector(
      onTap: () => context.push(Destinations.item(episode.id)),
      child: Container(
        height: isMobile ? 90.0 : 110.0,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
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
                      imageUrl: imageApi.getPrimaryImageUrl(
                        episode.id,
                        maxHeight: 220,
                        tag: episode.primaryImageTag,
                      ),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.white.withValues(alpha: 0.05),
                        child: const Icon(Icons.movie, color: Colors.white24, size: 32),
                      ),
                    )
                  else
                    Container(
                      color: Colors.white.withValues(alpha: 0.05),
                      child: const Icon(Icons.movie, color: Colors.white24, size: 32),
                    ),
                  if ((episode.playedPercentage ?? 0) > 0)
                    _EpisodeProgressBar(percentage: episode.playedPercentage!),
                  if (episode.isPlayed)
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(Icons.check_circle, color: Colors.green, size: 20),
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
    String? imageUrl;
    if (item.primaryImageTag != null) {
      imageUrl = imageApi.getPrimaryImageUrl(item.id, maxHeight: 400, tag: item.primaryImageTag);
    }

    final avatarRadius = isMobile ? 60.0 : 80.0;
    final avatar = CircleAvatar(
      radius: avatarRadius,
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
      child: imageUrl == null
          ? Icon(Icons.person, color: Colors.white54, size: isMobile ? 48 : 64)
          : null,
    );

    final info = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (!isMobile) const SizedBox(height: 16),
        Text(
          item.name,
          style: (isMobile ? theme.textTheme.headlineSmall : theme.textTheme.headlineLarge)?.copyWith(
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
      padding: EdgeInsets.only(top: isMobile ? 60 : 80),
      child: isMobile
          ? Column(
              children: [
                avatar,
                const SizedBox(height: 16),
                info,
              ],
            )
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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  int _calculateAge(DateTime birth) {
    final now = DateTime.now();
    var age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
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
          firstChild: Text(widget.text, style: style, maxLines: 4, overflow: TextOverflow.ellipsis),
          secondChild: Text(widget.text, style: style),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
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

  const _FilmographyRow({required this.items, required this.imageApi, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final watchedBehavior = prefs.get(UserPreferences.watchedIndicatorBehavior);
    final isMobile = _isCompact(context);
    final cardWidth = isMobile ? 120.0 : 150.0;

    return SizedBox(
      height: isMobile ? 220 : 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: isMobile ? 8 : 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final year = item.productionYear;

          return MediaCard(
            title: item.name,
            subtitle: year?.toString(),
            imageUrl: item.primaryImageTag != null
                ? imageApi.getPrimaryImageUrl(item.id, maxHeight: isMobile ? 300 : 400, tag: item.primaryImageTag)
                : null,
            width: cardWidth,
            aspectRatio: 2 / 3,
            isFavorite: item.isFavorite,
            isPlayed: item.isPlayed,
            playedPercentage: item.playedPercentage,
            watchedBehavior: watchedBehavior,
            itemType: item.type,
            onTap: () => context.push(Destinations.item(item.id)),
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
    String? imageUrl;
    if (item.primaryImageTag != null) {
      imageUrl = imageApi.getPrimaryImageUrl(item.id, maxHeight: 400, tag: item.primaryImageTag);
    }

    final avatarRadius = isMobile ? 60.0 : 80.0;
    final avatar = CircleAvatar(
      radius: avatarRadius,
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
      child: imageUrl == null
          ? Icon(Icons.music_note, color: Colors.white54, size: isMobile ? 48 : 64)
          : null,
    );

    final info = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (!isMobile) const SizedBox(height: 16),
        Text(
          item.name,
          style: (isMobile ? theme.textTheme.headlineSmall : theme.textTheme.headlineLarge)?.copyWith(
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
      padding: EdgeInsets.only(top: isMobile ? 60 : 80),
      child: isMobile
          ? Column(
              children: [
                avatar,
                const SizedBox(height: 16),
                info,
              ],
            )
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

  const _AlbumHeader({required this.item, required this.imageApi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = _isCompact(context);
    final albumSize = isMobile ? 150.0 : 200.0;

    final albumArt = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: item.primaryImageTag != null
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
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (!isMobile) const SizedBox(height: 16),
        Text(
          item.name,
          style: (isMobile ? theme.textTheme.headlineSmall : theme.textTheme.headlineLarge)?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: _textShadows,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        if (item.albumArtist != null) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              final artistId = item.albumArtists.isNotEmpty
                  ? item.albumArtists.first['Id'] as String?
                  : null;
              if (artistId != null) {
                context.push(Destinations.item(artistId));
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
      padding: EdgeInsets.only(top: isMobile ? 60 : 80),
      child: isMobile
          ? Column(
              children: [
                albumArt,
                const SizedBox(height: 16),
                info,
              ],
            )
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

class _AlbumsRow extends StatelessWidget {
  final List<AggregatedItem> albums;
  final ImageApi imageApi;
  final UserPreferences prefs;

  const _AlbumsRow({required this.albums, required this.imageApi, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final watchedBehavior = prefs.get(UserPreferences.watchedIndicatorBehavior);
    final isMobile = _isCompact(context);
    final cardWidth = isMobile ? 120.0 : 150.0;

    return SizedBox(
      height: isMobile ? 180 : 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: albums.length,
        separatorBuilder: (_, __) => SizedBox(width: isMobile ? 8 : 12),
        itemBuilder: (context, index) {
          final album = albums[index];
          return MediaCard(
            title: album.name,
            subtitle: album.productionYear?.toString(),
            imageUrl: album.primaryImageTag != null
                ? imageApi.getPrimaryImageUrl(album.id, maxHeight: isMobile ? 240 : 300, tag: album.primaryImageTag)
                : null,
            width: cardWidth,
            aspectRatio: 1.0,
            watchedBehavior: watchedBehavior,
            itemType: album.type,
            onTap: () => context.push(Destinations.item(album.id)),
          );
        },
      ),
    );
  }
}

class _TrackList extends StatelessWidget {
  final List<AggregatedItem> tracks;

  const _TrackList({required this.tracks});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(tracks.length, (index) {
        return _TrackTile(
          track: tracks[index],
          index: index + 1,
        );
      }),
    );
  }
}

class _TrackTile extends StatelessWidget {
  final AggregatedItem track;
  final int index;

  const _TrackTile({required this.track, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final runtime = track.runtime;
    final runtimeText = runtime != null
        ? '${runtime.inMinutes}:${(runtime.inSeconds % 60).toString().padLeft(2, '0')}'
        : null;
    final trackNumber = track.indexNumber ?? index;

    return GestureDetector(
      onLongPress: () => _showTrackActions(context),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: index.isOdd ? Colors.white.withValues(alpha: 0.04) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  trackNumber.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
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
                    track.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (track.artists.isNotEmpty)
                    Text(
                      track.artists.join(', '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (runtimeText != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  runtimeText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow, color: Colors.white54, size: 22),
              splashRadius: 20,
            ),
            IconButton(
              onPressed: () => _showTrackActions(context),
              icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
              splashRadius: 20,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  void _showTrackActions(BuildContext context) {
    TrackActionDialog.show(
      context,
      track: track,
      onPlay: () {},
      onPlayNext: () {},
      onAddToQueue: () {},
      onAddToPlaylist: () => AddToPlaylistDialog.show(context, itemIds: [track.id]),
      onToggleFavorite: () {
        GetIt.instance<ItemMutationRepository>().setFavorite(
          track.id,
          isFavorite: !track.isFavorite,
        );
      },
    );
  }
}
