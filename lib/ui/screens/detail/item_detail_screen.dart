import 'dart:async';
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
import '../../../data/viewmodels/item_detail_view_model.dart';
import '../../../preference/user_preferences.dart';
import '../../navigation/destinations.dart';
import '../../widgets/logo_view.dart';
import '../../widgets/media_card.dart';
import '../../widgets/navigation_layout.dart';
import '../../widgets/rating_display.dart';

const _textShadows = [Shadow(blurRadius: 4, color: Colors.black54)];

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late final ItemDetailViewModel _viewModel;
  final _backgroundService = GetIt.instance<BackgroundService>();
  final _prefs = GetIt.instance<UserPreferences>();
  StreamSubscription<String?>? _backgroundSub;
  String? _backdropUrl;

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

    _backgroundSub = _backgroundService.backgroundStream.listen((url) {
      if (mounted) setState(() => _backdropUrl = url);
    });
    _backdropUrl = _backgroundService.currentUrl;
  }

  @override
  void dispose() {
    _backgroundSub?.cancel();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NavigationLayout(
        child: _buildBody(context),
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
              padding: const EdgeInsets.symmetric(horizontal: 48),
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
      _ => _buildMovieContent(item),
    };
  }

  List<Widget> _overviewSection(AggregatedItem item) {
    if (item.overview == null || item.overview!.isEmpty) return const [];
    return [
      const SizedBox(height: 24),
      _OverviewText(text: item.overview!),
    ];
  }

  List<Widget> _buildMovieContent(AggregatedItem item) {
    return [
      _ActionButtons(viewModel: viewModel),
      ..._overviewSection(item),
      if (viewModel.actors.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'Cast'),
        const SizedBox(height: 12),
        _CastRow(people: viewModel.actors, imageApi: viewModel.imageApi),
      ],
      if (viewModel.similar.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'More Like This'),
        const SizedBox(height: 12),
        _SimilarRow(items: viewModel.similar, imageApi: viewModel.imageApi, prefs: prefs),
      ],
      if (_hasExtendedInfo(item)) ...[
        const SizedBox(height: 32),
        _ExtendedInfo(viewModel: viewModel),
      ],
      const SizedBox(height: 48),
    ];
  }

  List<Widget> _buildSeriesContent(AggregatedItem item) {
    return [
      _ActionButtons(viewModel: viewModel),
      ..._overviewSection(item),
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
        _SectionHeader(title: 'Cast'),
        const SizedBox(height: 12),
        _CastRow(people: viewModel.actors, imageApi: viewModel.imageApi),
      ],
      if (_hasExtendedInfo(item)) ...[
        const SizedBox(height: 32),
        _ExtendedInfo(viewModel: viewModel),
      ],
      const SizedBox(height: 48),
    ];
  }

  List<Widget> _buildSeasonContent(AggregatedItem item) {
    return [
      _ActionButtons(viewModel: viewModel),
      ..._overviewSection(item),
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
      ..._overviewSection(item),
      if (viewModel.actors.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'Cast'),
        const SizedBox(height: 12),
        _CastRow(people: viewModel.actors, imageApi: viewModel.imageApi),
      ],
      if (item.seriesId != null) ...[
        const SizedBox(height: 32),
        _EpisodeNavigationRow(item: item),
      ],
      const SizedBox(height: 48),
    ];
  }

  List<Widget> _buildPersonContent(AggregatedItem item) {
    return [
      _PersonHeader(item: item, imageApi: viewModel.imageApi),
      if (item.overview != null && item.overview!.isNotEmpty) ...[
        const SizedBox(height: 24),
        _ExpandableBiography(text: item.overview!),
      ],
      if (viewModel.filmography.isNotEmpty) ...[
        const SizedBox(height: 32),
        _SectionHeader(title: 'Filmography'),
        const SizedBox(height: 12),
        _FilmographyRow(items: viewModel.filmography, imageApi: viewModel.imageApi, prefs: prefs),
      ],
      const SizedBox(height: 48),
    ];
  }

  List<Widget> _buildArtistContent(AggregatedItem item) {
    return [
      _ArtistHeader(item: item, imageApi: viewModel.imageApi),
      ..._overviewSection(item),
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

  bool _hasExtendedInfo(AggregatedItem item) {
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

class _HeaderSection extends StatelessWidget {
  final ItemDetailViewModel viewModel;
  final UserPreferences prefs;

  const _HeaderSection({required this.viewModel, required this.prefs});

  @override
  Widget build(BuildContext context) {
    final item = viewModel.item!;
    final imageApi = viewModel.imageApi;
    final isEpisode = item.type == 'Episode';

    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 80, 48, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isEpisode)
            _EpisodeThumbnail(item: item, imageApi: imageApi)
          else
            _PosterImage(item: item, imageApi: imageApi),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isEpisode && item.seriesName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      item.seriesName!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            shadows: _textShadows,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (!isEpisode && item.logoImageTag != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LogoView(
                      imageUrl: imageApi.getLogoImageUrl(item.id, tag: item.logoImageTag),
                      maxHeight: 80,
                      maxWidth: 350,
                    ),
                  )
                else
                  Text(
                    isEpisode ? _episodeTitle(item) : item.name,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: _textShadows,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (item.tagline != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.tagline!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                          shadows: _textShadows,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                _MetadataRow(item: item),
                const SizedBox(height: 6),
                _TechBadgeRow(item: item),
                if (viewModel.ratings.isNotEmpty ||
                    item.communityRating != null ||
                    item.criticRating != null) ...[
                  const SizedBox(height: 8),
                  RatingsRow(
                    ratings: viewModel.ratings,
                    baseUrl: viewModel.baseUrl,
                    communityRating: item.communityRating,
                    criticRating: item.criticRating,
                    enableAdditionalRatings: prefs.get(UserPreferences.enableAdditionalRatings),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _episodeTitle(AggregatedItem item) {
    final s = item.parentIndexNumber;
    final e = item.indexNumber;
    final prefix = (s != null && e != null) ? 'S${s}E$e - ' : '';
    return '$prefix${item.name}';
  }
}

class _PosterImage extends StatelessWidget {
  final AggregatedItem item;
  final ImageApi imageApi;

  const _PosterImage({required this.item, required this.imageApi});

  @override
  Widget build(BuildContext context) {
    if (item.primaryImageTag == null) return const SizedBox(width: 180, height: 270);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageApi.getPrimaryImageUrl(
          item.id,
          maxHeight: 540,
          tag: item.primaryImageTag,
        ),
        width: 180,
        height: 270,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => const SizedBox(width: 180, height: 270),
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
    if (item.primaryImageTag == null) return const SizedBox(width: 240, height: 135);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageApi.getPrimaryImageUrl(
          item.id,
          maxWidth: 480,
          tag: item.primaryImageTag,
        ),
        width: 240,
        height: 135,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => const SizedBox(width: 240, height: 135),
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

    if (item.endsAt != null && item.type != 'Series') {
      parts.add(_text(theme, 'Ends at ${item.endsAt}'));
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

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      runSpacing: 4,
      children: separated,
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
}

class _TechBadgeRow extends StatelessWidget {
  final AggregatedItem item;

  const _TechBadgeRow({required this.item});

  @override
  Widget build(BuildContext context) {
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

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: badges.map((b) => _chip(context, b)).toList(),
    );
  }

  Widget _chip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.play_arrow),
          label: Text(hasProgress ? 'Resume' : 'Play'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF00A4DC),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        if (hasProgress)
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.restart_alt),
            label: const Text('Play from Start'),
            style: _outlinedStyle(),
          ),
        if (item.remoteTrailers.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.movie_outlined),
            label: const Text('Trailer'),
            style: _outlinedStyle(),
          ),
        OutlinedButton.icon(
          onPressed: viewModel.toggleFavorite,
          icon: Icon(item.isFavorite ? Icons.favorite : Icons.favorite_border),
          label: Text(item.isFavorite ? 'Favorited' : 'Favorite'),
          style: _outlinedStyle(),
        ),
        OutlinedButton.icon(
          onPressed: viewModel.togglePlayed,
          icon: Icon(item.isPlayed ? Icons.check_circle : Icons.check_circle_outline),
          label: Text(item.isPlayed ? 'Watched' : 'Unwatched'),
          style: _outlinedStyle(),
        ),
      ],
    );
  }

  ButtonStyle _outlinedStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: people.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final person = people[index];
          final name = person['Name'] as String? ?? '';
          final role = person['Role'] as String?;
          final personId = person['Id'] as String?;
          final tag = person['PrimaryImageTag'] as String?;

          String? imageUrl;
          if (personId != null && tag != null) {
            imageUrl = imageApi.getPrimaryImageUrl(personId, maxHeight: 200, tag: tag);
          }

          return GestureDetector(
            onTap: personId != null ? () => context.go(Destinations.item(personId)) : null,
            child: SizedBox(
              width: 100,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    backgroundImage: imageUrl != null
                        ? CachedNetworkImageProvider(imageUrl)
                        : null,
                    child: imageUrl == null
                        ? const Icon(Icons.person, color: Colors.white54, size: 32)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
                            fontSize: 11,
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

    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final ar = MediaCard.aspectRatioForType(item.type);
          return MediaCard(
            title: item.name,
            imageUrl: item.primaryImageTag != null
                ? imageApi.getPrimaryImageUrl(
                    item.id,
                    maxHeight: 400,
                    tag: item.primaryImageTag,
                  )
                : null,
            width: 150,
            aspectRatio: ar,
            isFavorite: item.isFavorite,
            isPlayed: item.isPlayed,
            playedPercentage: item.playedPercentage,
            watchedBehavior: watchedBehavior,
            itemType: item.type,
            onTap: () => context.go(Destinations.item(item.id)),
          );
        },
      ),
    );
  }
}

class _ExtendedInfo extends StatelessWidget {
  final ItemDetailViewModel viewModel;

  const _ExtendedInfo({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final item = viewModel.item!;
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.5),
      fontWeight: FontWeight.w600,
    );
    final valueStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.9),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Details'),
        const SizedBox(height: 12),
        if (viewModel.directors.isNotEmpty)
          _infoLine(
            'Director',
            viewModel.directors.map((d) => d['Name'] as String).join(', '),
            labelStyle!,
            valueStyle!,
          ),
        if (viewModel.writers.isNotEmpty)
          _infoLine(
            'Writers',
            viewModel.writers.map((w) => w['Name'] as String).join(', '),
            labelStyle!,
            valueStyle!,
          ),
        if (item.studios.isNotEmpty)
          _infoLine(
            'Studio',
            item.studios.map((s) => s['Name'] as String).join(', '),
            labelStyle!,
            valueStyle!,
          ),
      ],
    );
  }

  Widget _infoLine(String label, String value, TextStyle labelStyle, TextStyle valueStyle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: labelStyle),
          ),
          Expanded(child: Text(value, style: valueStyle)),
        ],
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

    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: seasons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final season = seasons[index];
          return MediaCard(
            title: season.name,
            subtitle: _progressText(season),
            imageUrl: season.primaryImageTag != null
                ? imageApi.getPrimaryImageUrl(
                    season.id,
                    maxHeight: 400,
                    tag: season.primaryImageTag,
                  )
                : null,
            width: 150,
            aspectRatio: 2 / 3,
            isPlayed: season.isPlayed,
            unplayedCount: season.unplayedItemCount,
            watchedBehavior: watchedBehavior,
            itemType: season.type,
            onTap: () => context.go(Destinations.item(season.id)),
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

    return GestureDetector(
      onTap: () => context.go(Destinations.item(episode.id)),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 213,
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

    return GestureDetector(
      onTap: () => context.go(Destinations.item(episode.id)),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 196,
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

class _EpisodeNavigationRow extends StatelessWidget {
  final AggregatedItem item;

  const _EpisodeNavigationRow({required this.item});

  static final _navButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        if (item.seriesId != null)
          OutlinedButton.icon(
            onPressed: () => context.go(Destinations.item(item.seriesId!)),
            icon: const Icon(Icons.tv),
            label: Text(item.seriesName ?? 'Go to Series'),
            style: _navButtonStyle,
          ),
        if (item.seasonId != null)
          OutlinedButton.icon(
            onPressed: () => context.go(Destinations.item(item.seasonId!)),
            icon: const Icon(Icons.list),
            label: Text(item.parentIndexNumber != null
                ? 'Season ${item.parentIndexNumber}'
                : 'Go to Season'),
            style: _navButtonStyle,
          ),
      ],
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
    String? imageUrl;
    if (item.primaryImageTag != null) {
      imageUrl = imageApi.getPrimaryImageUrl(item.id, maxHeight: 400, tag: item.primaryImageTag);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 80,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
            child: imageUrl == null
                ? const Icon(Icons.person, color: Colors.white54, size: 64)
                : null,
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  item.name,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: _textShadows,
                  ),
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
            ),
          ),
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

    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          final year = item.productionYear;

          return MediaCard(
            title: item.name,
            subtitle: year?.toString(),
            imageUrl: item.primaryImageTag != null
                ? imageApi.getPrimaryImageUrl(item.id, maxHeight: 400, tag: item.primaryImageTag)
                : null,
            width: 150,
            aspectRatio: 2 / 3,
            isFavorite: item.isFavorite,
            isPlayed: item.isPlayed,
            playedPercentage: item.playedPercentage,
            watchedBehavior: watchedBehavior,
            itemType: item.type,
            onTap: () => context.go(Destinations.item(item.id)),
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
    String? imageUrl;
    if (item.primaryImageTag != null) {
      imageUrl = imageApi.getPrimaryImageUrl(item.id, maxHeight: 400, tag: item.primaryImageTag);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 80,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
            child: imageUrl == null
                ? const Icon(Icons.music_note, color: Colors.white54, size: 64)
                : null,
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  item.name,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: _textShadows,
                  ),
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
            ),
          ),
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

    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.primaryImageTag != null
                ? CachedNetworkImage(
                    imageUrl: imageApi.getPrimaryImageUrl(
                      item.id,
                      maxHeight: 400,
                      tag: item.primaryImageTag,
                    ),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _albumPlaceholder(),
                  )
                : _albumPlaceholder(),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  item.name,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: _textShadows,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.albumArtist != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      final artistId = item.albumArtists.isNotEmpty
                          ? item.albumArtists.first['Id'] as String?
                          : null;
                      if (artistId != null) {
                        context.go(Destinations.item(artistId));
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _albumPlaceholder() {
    return Container(
      width: 200,
      height: 200,
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

    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final album = albums[index];
          return MediaCard(
            title: album.name,
            subtitle: album.productionYear?.toString(),
            imageUrl: album.primaryImageTag != null
                ? imageApi.getPrimaryImageUrl(album.id, maxHeight: 300, tag: album.primaryImageTag)
                : null,
            width: 150,
            aspectRatio: 1.0,
            watchedBehavior: watchedBehavior,
            itemType: album.type,
            onTap: () => context.go(Destinations.item(album.id)),
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

    return Container(
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
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
