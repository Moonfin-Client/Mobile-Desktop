import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/models/home_row.dart';
import '../../../data/services/background_service.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';
import '../../navigation/destinations.dart';
import '../../../data/models/media_bar_state.dart';
import '../../../data/viewmodels/media_bar_view_model.dart';
import '../../widgets/grid_button_card.dart';
import '../../widgets/info_area.dart';
import '../../widgets/library_row.dart';
import '../../widgets/media_bar.dart';
import '../../widgets/media_card.dart';
import '../../widgets/navigation_layout.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/seasonal_effects.dart';
import 'home_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobileBody: _HomeShell(),
      tvBody: _HomeShell(),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  final _backgroundService = GetIt.instance<BackgroundService>();
  final _userPrefs = GetIt.instance<UserPreferences>();
  late final HomeViewModel _viewModel;

  AggregatedItem? _selectedItem;
  String? _backdropUrl;
  Timer? _selectionDebounce;
  Timer? _backdropDebounce;
  Timer? _hoverPauseTimer;
  StreamSubscription<String?>? _backgroundSub;
  bool _isHoverPaused = false;
  bool _isScrolledToTop = true;
  String _lastSectionsJson = '';
  bool _lastMultiServer = false;

  static const _selectionDelay = Duration(milliseconds: 150);
  static const _backdropDelay = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _backgroundSub = _backgroundService.backgroundStream.listen((url) {
      if (mounted) setState(() => _backdropUrl = url);
    });
    _backdropUrl = _backgroundService.currentUrl;

    _viewModel = GetIt.instance<HomeViewModel>();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.mediaBarViewModel.addListener(_onViewModelChanged);
    _lastSectionsJson = _userPrefs.get(UserPreferences.homeSectionsJson);
    _lastMultiServer = _userPrefs.get(UserPreferences.enableMultiServerLibraries);
    _userPrefs.addListener(_onPrefsChanged);
    _viewModel.load();
  }

  @override
  void dispose() {
    _selectionDebounce?.cancel();
    _backdropDebounce?.cancel();
    _hoverPauseTimer?.cancel();
    _backgroundSub?.cancel();
    _viewModel.mediaBarViewModel.removeListener(_onViewModelChanged);
    _viewModel.removeListener(_onViewModelChanged);
    _userPrefs.removeListener(_onPrefsChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  void _onPrefsChanged() {
    if (!mounted) return;
    final currentJson = _userPrefs.get(UserPreferences.homeSectionsJson);
    final currentMultiServer = _userPrefs.get(UserPreferences.enableMultiServerLibraries);
    if (currentJson != _lastSectionsJson || currentMultiServer != _lastMultiServer) {
      _lastSectionsJson = currentJson;
      _lastMultiServer = currentMultiServer;
      _viewModel.refresh();
    }
    setState(() {});
  }

  void onItemSelected(AggregatedItem? item) {
    _selectionDebounce?.cancel();
    _selectionDebounce = Timer(_selectionDelay, () {
      if (!mounted) return;
      setState(() {
        _selectedItem = item;
        _isHoverPaused = true;
      });

      _hoverPauseTimer?.cancel();
      _hoverPauseTimer = Timer(const Duration(seconds: 15), () {
        if (mounted) setState(() => _isHoverPaused = false);
      });

      _backdropDebounce?.cancel();
      _backdropDebounce = Timer(_backdropDelay, () {
        _backgroundService.setBackground(item, context: BlurContext.browsing);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final backdropEnabled = _userPrefs.get(UserPreferences.backdropEnabled);
    final blurAmount = _userPrefs.get(UserPreferences.browsingBackgroundBlurAmount).toDouble();
    final seasonalEffect = _userPrefs.get(UserPreferences.seasonalSurprise);
    final confirmExit = PlatformDetection.isDesktop &&
        _userPrefs.get(UserPreferences.confirmExit);

    return PopScope(
      canPop: !confirmExit,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showExitConfirmation(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: NavigationLayout(
          activeRoute: Destinations.home,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (backdropEnabled) _Backdrop(url: _backdropUrl, blurAmount: blurAmount),
              const _GradientScrim(),
              Positioned.fill(
                child: _ContentRows(
                  viewModel: _viewModel,
                  mediaBarViewModel: _viewModel.mediaBarViewModel,
                  prefs: _userPrefs,
                  selectedItem: _selectedItem,
                  onItemSelected: onItemSelected,
                  isHoverPaused: _isHoverPaused,
                  onScrolledToTopChanged: (atTop) {
                    if (atTop != _isScrolledToTop) {
                      setState(() => _isScrolledToTop = atTop);
                    }
                  },
                ),
              ),
              if (seasonalEffect != 'none')
                Positioned.fill(
                  child: SeasonalEffects(effect: seasonalEffect),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showExitConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Moonfin?'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (result == true) {
      SystemNavigator.pop();
    }
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
      imageFilter: ui.ImageFilter.blur(
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
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xAA000000),
            Color(0x44000000),
            Color(0xBB000000),
          ],
          stops: [0.0, 0.3, 1.0],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _ContentRows extends StatefulWidget {
  final HomeViewModel viewModel;
  final MediaBarViewModel mediaBarViewModel;
  final UserPreferences prefs;
  final AggregatedItem? selectedItem;
  final ValueChanged<AggregatedItem?> onItemSelected;
  final bool isHoverPaused;
  final ValueChanged<bool>? onScrolledToTopChanged;

  const _ContentRows({
    required this.viewModel,
    required this.mediaBarViewModel,
    required this.prefs,
    required this.selectedItem,
    required this.onItemSelected,
    this.isHoverPaused = false,
    this.onScrolledToTopChanged,
  });

  @override
  State<_ContentRows> createState() => _ContentRowsState();
}

class _ContentRowsState extends State<_ContentRows> {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;
  bool _isScrolledToTop = true;
  bool _infoRevealed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final atTop = offset <= 0;
    if (atTop != _isScrolledToTop) {
      _isScrolledToTop = atTop;
      widget.onScrolledToTopChanged?.call(atTop);
      if (atTop) _infoRevealed = false;
    }
    setState(() => _scrollOffset = offset);
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.viewModel.rows;
    final prefs = widget.prefs;
    final posterSize = prefs.get(UserPreferences.posterSize);
    final watchedBehavior = prefs.get(UserPreferences.watchedIndicatorBehavior);
    final focusColor = Color(prefs.get(UserPreferences.focusColor).colorValue);
    final cardExpansion = prefs.get(UserPreferences.cardFocusExpansion);
    final useSeriesThumbs = prefs.get(UserPreferences.seriesThumbnailsEnabled);

    if (widget.viewModel.isLoading && rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final mediaBarState = widget.mediaBarViewModel.state;
    final includeMediaBar = mediaBarState is MediaBarLoading ||
        mediaBarState is MediaBarError ||
        (mediaBarState is MediaBarReady && mediaBarState.items.isNotEmpty);

    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = PlatformDetection.useMobileUi;
    final mediaBarHeight = isMobile ? screenHeight * 0.55 : screenHeight;
    final carouselPaused = widget.isHoverPaused || !_isScrolledToTop;

    final pinThreshold = includeMediaBar ? mediaBarHeight : 0.0;
    final infoAreaIsPinned = _scrollOffset > pinThreshold;
    final headerCount = (includeMediaBar ? 1 : 0) + 1;

    return Stack(
      children: [
        Positioned.fill(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.only(
              top: includeMediaBar ? 0 : MediaQuery.of(context).padding.top + 56,
              bottom: 32,
            ),
            itemCount: rows.length + headerCount,
            itemBuilder: (context, index) {
              if (includeMediaBar && index == 0) {
                return MediaBar(
                  viewModel: widget.mediaBarViewModel,
                  prefs: prefs,
                  externallyPaused: carouselPaused,
                  height: mediaBarHeight,
                );
              }
              final infoIndex = includeMediaBar ? 1 : 0;
              if (index == infoIndex) {
                if (!_infoRevealed || (isMobile && _scrollOffset == 0)) {
                  return const SizedBox.shrink();
                }
                final safeTop = MediaQuery.of(context).padding.top;
                final topPad = !includeMediaBar ? safeTop + 48 : 8.0;
                final bottomPad = safeTop + 48 - topPad + 8;
                final showInList = !infoAreaIsPinned && _infoRevealed &&
                    (!isMobile || _scrollOffset > 0);
                return Opacity(
                  opacity: showInList ? 1.0 : 0.0,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, topPad, 16, bottomPad),
                    child: InfoArea(item: widget.selectedItem),
                  ),
                );
              }
              final row = rows[index - headerCount];
              if (row.isLoading) {
                return LibraryRow(title: row.title, children: const []);
              }
              if (row.rowType == HomeRowType.liveTv) {
                return _buildLiveTvRow(row, focusColor);
              }
              if (row.rowType == HomeRowType.libraryTilesSmall) {
                return _buildLibraryButtonsRow(row, focusColor);
              }
              double maxCardHeight = 0;
              final useLandscape = row.rowType == HomeRowType.resume ||
                  row.rowType == HomeRowType.nextUp ||
                  row.rowType == HomeRowType.libraryTiles;
              final cards = row.items.map((item) {
                final ar = useLandscape ? 16 / 9 : MediaCard.aspectRatioForType(item.type);
                final height = ar > 1
                    ? posterSize.landscapeHeight.toDouble()
                    : posterSize.portraitHeight.toDouble();
                final cardHeight = height + 46;
                if (cardHeight > maxCardHeight) maxCardHeight = cardHeight;
                final width = height * ar;
                final imageUrl = useLandscape
                    ? _resolveLandscapeImageUrl(
                        item, widget.viewModel.imageApiForServer(item.serverId), height)
                    : _resolveImageUrl(
                        item, widget.viewModel.imageApiForServer(item.serverId), height, useSeriesThumbs,
                      );
                return MediaCard(
                  title: item.name,
                  subtitle: item.subtitle,
                  imageUrl: imageUrl,
                  width: width,
                  aspectRatio: ar,
                  isFavorite: item.isFavorite,
                  isPlayed: item.isPlayed,
                  unplayedCount: item.unplayedItemCount,
                  playedPercentage: item.playedPercentage,
                  watchedBehavior: watchedBehavior,
                  itemType: item.type,
                  focusColor: focusColor,
                  cardFocusExpansion: cardExpansion,
                  onFocus: () => widget.onItemSelected(item),
                  onHoverStart: () {
                    if (!_infoRevealed) {
                      setState(() => _infoRevealed = true);
                    }
                    widget.onItemSelected(item);
                  },
                  onLongPress: () {
                    if (!_infoRevealed) {
                      setState(() => _infoRevealed = true);
                    }
                    widget.onItemSelected(item);
                  },
                  onTap: () {
                    if (row.rowType == HomeRowType.libraryTiles) {
                      _navigateToLibrary(context, item);
                    } else {
                      context.push(Destinations.itemOrPhoto(item.id, serverId: item.serverId, type: item.type));
                    }
                  },
                );
              }).toList();
              return LibraryRow(
                title: row.title,
                rowHeight: maxCardHeight,
                children: cards,
              );
            },
          ),
        ),
        if (infoAreaIsPinned && _infoRevealed)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black.withValues(alpha: 0.7),
                        Colors.black.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.85, 1.0],
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + 48,
                    16,
                    8,
                  ),
                  child: InfoArea(item: widget.selectedItem),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLiveTvRow(HomeRow row, Color focusColor) {
    return LibraryRow(
      title: row.title,
      rowHeight: 140,
      children: [
        GridButtonCard(
          icon: Icons.tv_rounded,
          label: 'Guide',
          focusColor: focusColor,
          onTap: () => context.push(Destinations.liveTvGuide),
        ),
        GridButtonCard(
          icon: Icons.fiber_manual_record_rounded,
          label: 'Recordings',
          focusColor: focusColor,
          onTap: () => context.push(Destinations.liveTvRecordings),
        ),
        GridButtonCard(
          icon: Icons.schedule_rounded,
          label: 'Schedule',
          focusColor: focusColor,
          onTap: () => context.push(Destinations.liveTvSchedule),
        ),
        GridButtonCard(
          icon: Icons.video_library_rounded,
          label: 'Series',
          focusColor: focusColor,
          onTap: () => context.push(Destinations.liveTvSeriesRecordings),
        ),
      ],
    );
  }

  Widget _buildLibraryButtonsRow(HomeRow row, Color focusColor) {
    return LibraryRow(
      title: row.title,
      rowHeight: 140,
      children: row.items.map((item) {
        final collectionType = (item.rawData['CollectionType'] as String? ?? '').toLowerCase();
        final icon = _iconForCollectionType(collectionType);
        return GridButtonCard(
          icon: icon,
          label: item.name,
          focusColor: focusColor,
          onTap: () => _navigateToLibrary(context, item),
        );
      }).toList(),
    );
  }

  static IconData _iconForCollectionType(String collectionType) {
    return switch (collectionType) {
      'movies' => Icons.movie,
      'tvshows' => Icons.tv,
      'music' => Icons.music_note,
      'books' => Icons.book,
      'photos' => Icons.photo,
      'homevideos' => Icons.videocam,
      'livetv' => Icons.live_tv,
      'playlists' => Icons.playlist_play,
      'boxsets' => Icons.collections_bookmark,
      _ => Icons.folder_rounded,
    };
  }

  static void _navigateToLibrary(BuildContext context, AggregatedItem item) {
    final collectionType = (item.rawData['CollectionType'] as String? ?? '').toLowerCase();
    switch (collectionType) {
      case 'music':
        context.push(Destinations.musicLibrary(item.id));
        return;
      case 'books':
        context.push(Destinations.folder(item.id));
        return;
      case 'livetv':
        context.push(Destinations.liveTvGuide);
        return;
      default:
        context.push(Destinations.library(item.id));
        return;
    }
  }

  static String? _resolveImageUrl(
    AggregatedItem item,
    ImageApi imageApi,
    double height,
    bool useSeriesThumbs,
  ) {
    final maxH = (height * 2).toInt();
    if (useSeriesThumbs &&
        item.type == 'Episode' &&
        item.seriesId != null &&
        item.seriesPrimaryImageTag != null) {
      return imageApi.getPrimaryImageUrl(
        item.seriesId!,
        maxHeight: maxH,
        tag: item.seriesPrimaryImageTag,
      );
    }
    if (item.primaryImageTag != null) {
      return imageApi.getPrimaryImageUrl(
        item.id,
        maxHeight: maxH,
        tag: item.primaryImageTag,
      );
    }
    return null;
  }

  static String? _resolveLandscapeImageUrl(
    AggregatedItem item,
    ImageApi imageApi,
    double height,
  ) {
    final maxW = (height * 16 / 9 * 2).toInt();
    if (item.backdropImageTags.isNotEmpty) {
      return imageApi.getBackdropImageUrl(
        item.id,
        maxWidth: maxW,
        tag: item.backdropImageTags.first,
      );
    }
    final parentId = item.parentBackdropItemId;
    final parentTags = item.parentBackdropImageTags;
    if (parentId != null && parentTags.isNotEmpty) {
      return imageApi.getBackdropImageUrl(
        parentId,
        maxWidth: maxW,
        tag: parentTags.first,
      );
    }
    if (item.primaryImageTag != null) {
      return imageApi.getPrimaryImageUrl(
        item.id,
        maxWidth: maxW,
        tag: item.primaryImageTag,
      );
    }
    return null;
  }
}
