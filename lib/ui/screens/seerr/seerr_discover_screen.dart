import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../data/services/seerr/seerr_api_models.dart';
import '../../../data/viewmodels/seerr_discover_view_model.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../../ui/mixins/focus_state_mixin.dart';
import '../../../util/platform_detection.dart';
import '../../navigation/destinations.dart';
import '../../widgets/library_row.dart';
import '../../widgets/media_card.dart';
import '../../widgets/navigation_layout.dart';
import '../../../l10n/app_localizations.dart';

const _tmdbPosterBase = 'https://image.tmdb.org/t/p/w300';
const _tmdbBackdropBase = 'https://image.tmdb.org/t/p/w1280';

class SeerrDiscoverScreen extends StatefulWidget {
  const SeerrDiscoverScreen({super.key});

  @override
  State<SeerrDiscoverScreen> createState() =>
      _SeerrDiscoverScreenState();
}

class _SeerrDiscoverScreenState extends State<SeerrDiscoverScreen> {
  SeerrDiscoverViewModel? _viewModel;
  final _prefs = GetIt.instance<UserPreferences>();

  SeerrDiscoverItem? _selectedItem;
  Timer? _selectionDebounce;
  Timer? _backdropDebounce;
  String? _backdropUrl;

  static const _selectionDelay = Duration(milliseconds: 150);
  static const _backdropDelay = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _prefs.addListener(_onPrefsChanged);
    _initViewModel();
  }

  Future<void> _initViewModel() async {
    final vm = await GetIt.instance.getAsync<SeerrDiscoverViewModel>();
    if (!mounted) return;
    vm.addListener(_onChanged);
    setState(() => _viewModel = vm);
    vm.load();
  }

  @override
  void dispose() {
    _selectionDebounce?.cancel();
    _backdropDebounce?.cancel();
    _viewModel?.removeListener(_onChanged);
    _prefs.removeListener(_onPrefsChanged);
    super.dispose();
  }

  void _onPrefsChanged() {
    _viewModel?.applyRowConfig();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onItemSelected(SeerrDiscoverItem item) {
    _selectionDebounce?.cancel();
    _selectionDebounce = Timer(_selectionDelay, () {
      if (!mounted) return;
      setState(() => _selectedItem = item);

      _backdropDebounce?.cancel();
      _backdropDebounce = Timer(_backdropDelay, () {
        if (!mounted) return;
        final backdrop = item.backdropPath;
        setState(() {
          _backdropUrl = backdrop != null ? '$_tmdbBackdropBase$backdrop' : null;
        });
      });
    });
  }

  void _onItemTap(SeerrDiscoverItem item) {
    final mediaType = item.mediaType ?? 'movie';
    context.push(
      Destinations.seerrMedia(item.id.toString()),
      extra: {'mediaType': mediaType},
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final navbarPosition = GetIt.instance<UserPreferences>().get(UserPreferences.navbarPosition);
    final navbarHeight = navbarPosition == NavbarPosition.top
        ? (PlatformDetection.isTV ? 95.0 : PlatformDetection.useMobileUi ? 60.0 : 80.0)
        : 40.0;
    return Scaffold(
      backgroundColor: Colors.black,
      body: NavigationLayout(
        showBackButton: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Backdrop(url: _backdropUrl),
            const _GradientScrim(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoPanel(item: _selectedItem, topInset: topPad + navbarHeight),
                Expanded(child: _buildContent()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context);
    final vm = _viewModel;
    if (vm == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.error != null && vm.rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              vm.error!,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: vm.refresh,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final rows = vm.rows;
    if (rows.isEmpty && vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final visibleRows = <(int, SeerrDiscoverRow)>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      visibleRows.add((i, row));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: visibleRows.length,
      itemBuilder: (context, index) {
        final (origIndex, row) = visibleRows[index];
        if (row.isGenreRow) return _buildGenreRow(row);
        if (row.isNetworkRow) return _buildNetworkRow(row);
        if (row.isStudioRow) return _buildStudioRow(row);
        return _buildMediaRow(row, origIndex);
      },
    );
  }

  Widget _buildMediaRow(SeerrDiscoverRow row, int rowIndex) {
    final focusColor =
      Color(GetIt.instance<UserPreferences>().get(UserPreferences.focusColor).colorValue);
    final cardExpansion =
      GetIt.instance<UserPreferences>().get(UserPreferences.cardFocusExpansion);
    final children = <Widget>[];
    for (final item in row.items) {
      children.add(MediaCard(
        title: item.displayTitle,
        subtitle: _yearFromItem(item),
        imageUrl: item.posterPath != null
            ? '$_tmdbPosterBase${item.posterPath}'
            : null,
        width: 130,
        aspectRatio: 2 / 3,
        seerrMediaType: item.mediaType,
        seerrStatus: item.mediaInfo?.status,
        focusColor: focusColor,
        cardFocusExpansion: cardExpansion,
        onTap: () => _onItemTap(item),
        onFocus: () => _onItemSelected(item),
        onHoverStart: () => _onItemSelected(item),
      ));
    }

    if (row.isLoading) {
      children.add(const SizedBox(
        width: 130,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification &&
            notification.metrics.extentAfter < 300 &&
            row.hasMore &&
            !row.isLoading) {
          _viewModel?.loadMore(rowIndex);
        }
        return false;
      },
      child: LibraryRow(
        title: row.title,
        rowHeight: 236,
        children: children,
      ),
    );
  }

  Widget _buildGenreRow(SeerrDiscoverRow row) {
    final mediaType = row.type == SeerrRowType.movieGenres ? 'movie' : 'tv';
    final children = row.genres.map((genre) {
      final backdrop = genre.backdrops.isNotEmpty
          ? '$_tmdbBackdropBase${genre.backdrops.first}'
          : null;
      return _GenreCard(
        name: genre.name,
        imageUrl: backdrop,
        onTap: () {
          final uri = Uri(
            path: Destinations.seerrBrowse,
            queryParameters: {
              'filterId': genre.id.toString(),
              'filterName': genre.name,
              'mediaType': mediaType,
              'filterType': 'genre',
            },
          );
          context.push(uri.toString());
        },
      );
    }).toList();

    return LibraryRow(
      title: row.title,
      rowHeight: 100,
      children: children,
    );
  }

  Widget _buildNetworkRow(SeerrDiscoverRow row) {
    final children = row.networks.map((network) {
      return _LogoCard(
        name: network.name,
        logoUrl: network.logoPath,
        onTap: () {
          final uri = Uri(
            path: Destinations.seerrBrowse,
            queryParameters: {
              'filterId': network.id.toString(),
              'filterName': network.name,
              'mediaType': 'tv',
              'filterType': 'network',
            },
          );
          context.push(uri.toString());
        },
      );
    }).toList();

    return LibraryRow(
      title: row.title,
      rowHeight: 100,
      children: children,
    );
  }

  Widget _buildStudioRow(SeerrDiscoverRow row) {
    final children = row.studios.map((studio) {
      return _LogoCard(
        name: studio.name,
        logoUrl: studio.logoPath,
        onTap: () {
          final uri = Uri(
            path: Destinations.seerrBrowse,
            queryParameters: {
              'filterId': studio.id.toString(),
              'filterName': studio.name,
              'mediaType': 'movie',
              'filterType': 'studio',
            },
          );
          context.push(uri.toString());
        },
      );
    }).toList();

    return LibraryRow(
      title: row.title,
      rowHeight: 100,
      children: children,
    );
  }

  static String? _yearFromItem(SeerrDiscoverItem item) {
    final date = item.releaseDate ?? item.firstAirDate;
    if (date == null || date.length < 4) return null;
    return date.substring(0, 4);
  }
}
class _Backdrop extends StatelessWidget {
  final String? url;
  const _Backdrop({this.url});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: url != null
          ? SizedBox.expand(
              key: ValueKey(url),
              child: CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            )
          : const SizedBox.expand(key: ValueKey('empty')),
    );
  }
}

class _GradientScrim extends StatelessWidget {
  const _GradientScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xCC000000),
            Color(0x55000000),
            Color(0xDD000000),
          ],
          stops: [0.0, 0.25, 0.6],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final SeerrDiscoverItem? item;
  final double topInset;
  const _InfoPanel({this.item, required this.topInset});

  @override
  Widget build(BuildContext context) {
    if (item == null) return const SizedBox(height: 140);

    final theme = Theme.of(context);
    const shadows = [Shadow(blurRadius: 4, color: Colors.black54)];
    final year = _SeerrDiscoverScreenState._yearFromItem(item!);
    final rating = item!.voteAverage;
    final l10n = AppLocalizations.of(context);
    final mediaType = item!.mediaType == 'tv' ? l10n.series : l10n.movie;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        key: ValueKey(item!.id),
        padding: EdgeInsets.fromLTRB(48, topInset + 20, 48, 8),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item!.displayTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: shadows,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (year != null)
                    Text(year,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          shadows: shadows,
                        )),
                  if (year != null && rating != null)
                    const SizedBox(width: 12),
                  if (rating != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 16, color: Color(0xFFFFC107)),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                            shadows: shadows,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(width: 12),
                  Text(mediaType,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white54,
                        shadows: shadows,
                      )),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: (theme.textTheme.bodySmall?.fontSize ?? 12) * 1.4 * 3,
                child: item!.overview != null && item!.overview!.isNotEmpty
                    ? Text(
                        item!.overview!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          shadows: shadows,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenreCard extends StatefulWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback? onTap;

  const _GenreCard({required this.name, this.imageUrl, this.onTap});

  @override
  State<_GenreCard> createState() => _GenreCardState();
}

class _GenreCardState extends State<_GenreCard> with FocusStateMixin {

  @override
  Widget build(BuildContext context) {
    final focusColor =
        Color(GetIt.instance<UserPreferences>().get(UserPreferences.focusColor).colorValue);
    return Focus(
      onFocusChange: (focused) => setFocused(focused),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setHovered(true),
          onExit: (_) => setHovered(false),
          child: AnimatedScale(
            scale: showFocusBorder ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: SizedBox(
              width: 180,
              height: 90,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.imageUrl != null)
                      CachedNetworkImage(
                        imageUrl: widget.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[800],
                        ),
                      )
                    else
                      Container(color: Colors.grey[800]),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xBB000000)],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Text(
                        widget.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showFocusBorder)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: focusColor, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoCard extends StatefulWidget {
  final String name;
  final String? logoUrl;
  final VoidCallback? onTap;

  const _LogoCard({required this.name, this.logoUrl, this.onTap});

  @override
  State<_LogoCard> createState() => _LogoCardState();
}

class _LogoCardState extends State<_LogoCard> with FocusStateMixin {

  @override
  Widget build(BuildContext context) {
    final focusColor =
        Color(GetIt.instance<UserPreferences>().get(UserPreferences.focusColor).colorValue);
    return Focus(
      onFocusChange: (focused) => setFocused(focused),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setHovered(true),
          onExit: (_) => setHovered(false),
          child: AnimatedScale(
            scale: showFocusBorder ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: SizedBox(
              width: 180,
              height: 90,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(8),
                    border: showFocusBorder
                      ? Border.all(color: focusColor, width: 2)
                      : null,
                ),
                child: widget.logoUrl != null
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: CachedNetworkImage(
                          imageUrl: widget.logoUrl!,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => Center(
                            child: Text(
                              widget.name,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          widget.name,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
