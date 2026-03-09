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
            SliverToBoxAdapter(child: _HeaderSection(viewModel: viewModel, prefs: prefs)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ActionButtons(viewModel: viewModel),
                  if (item.overview != null && item.overview!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      item.overview!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            shadows: _textShadows,
                            height: 1.5,
                          ),
                    ),
                  ],
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
                ]),
              ),
            ),
          ],
        ),
      ],
    );
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 80, 48, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _PosterImage(item: item, imageApi: imageApi),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (item.logoImageTag != null)
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
                    item.name,
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
