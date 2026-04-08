import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:server_core/server_core.dart';

import '../../data/models/media_bar_slide_item.dart';
import '../../data/models/media_bar_state.dart';
import '../../data/services/media_server_client_factory.dart';
import '../../data/services/youtube_stream_resolver.dart';
import '../../data/viewmodels/media_bar_view_model.dart';
import '../../preference/preference_constants.dart';
import '../../preference/user_preferences.dart';
import '../navigation/destinations.dart';
import '../../util/platform_detection.dart';
import '../../l10n/app_localizations.dart';
import 'rating_display.dart';

const _textShadows = [Shadow(blurRadius: 4, color: Colors.black54)];

class MediaBar extends StatefulWidget {
  final MediaBarViewModel viewModel;
  final UserPreferences prefs;
  final bool externallyPaused;
  final double height;

  const MediaBar({
    super.key,
    required this.viewModel,
    required this.prefs,
    this.externallyPaused = false,
    this.height = 220,
  });

  @override
  State<MediaBar> createState() => _MediaBarState();
}

class _MediaBarState extends State<MediaBar> with WidgetsBindingObserver {
  static const _openTimeout = Duration(seconds: 10);
  static const _previewRevealDelay = Duration(seconds: 3);

  final _pageController = PageController();
  RouteInformationProvider? _routeInformationProvider;
  bool _isHomeRouteActive = true;

  Timer? _autoAdvanceTimer;
  bool _isPaused = false;
  int _currentIndex = 0;

  Player? _trailerPlayer;
  VideoController? _trailerController;
  StreamSubscription<bool>? _trailerCompletedSub;
  Timer? _trailerRevealTimer;
  double _trailerVideoOpacity = 0.0;
  String? _activeTrailerItemId;
  int _trailerResolveId = 0;
  bool _trailerRevealArmed = false;
  bool _isTrailerPlaying = false;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onStateChanged);
    widget.prefs.addListener(_onPrefsChanged);
    WidgetsBinding.instance.addObserver(this);
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
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _trailerRevealTimer?.cancel();
    _trailerCompletedSub?.cancel();
    _trailerPlayer?.stop();
    _trailerPlayer?.dispose();
    _pageController.dispose();
    widget.viewModel.removeListener(_onStateChanged);
    widget.prefs.removeListener(_onPrefsChanged);
    WidgetsBinding.instance.removeObserver(this);
    _routeInformationProvider?.removeListener(_onRouteChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(MediaBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externallyPaused != oldWidget.externallyPaused) {
      if (widget.externallyPaused) {
        _autoAdvanceTimer?.cancel();
        _cancelTrailerPreview();
      } else {
        _startAutoAdvance();
        final items = widget.viewModel.items;
        if (_isHomeRouteActive && _currentIndex < items.length) {
          _scheduleTrailerPreview(items[_currentIndex]);
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _cancelTrailerPreview();
    }
  }

  void _onStateChanged() {
    if (!mounted) return;
    setState(() {});
    final state = widget.viewModel.state;
    if (_isHomeRouteActive && state is MediaBarReady && state.items.isNotEmpty) {
      _startAutoAdvance();
      if (_activeTrailerItemId == null && _currentIndex < state.items.length) {
        _scheduleTrailerPreview(state.items[_currentIndex]);
      }
    }
  }

  void _onPrefsChanged() {
    if (!mounted) return;
    setState(() {});
    if (!widget.prefs.get(UserPreferences.mediaBarTrailerPreview)) {
      _cancelTrailerPreview();
    } else if (_trailerPlayer != null) {
      final audioEnabled = widget.prefs.get(UserPreferences.previewAudioEnabled);
      _trailerPlayer?.setVolume(audioEnabled ? 100 : 0);
    }
  }

  void _onRouteChanged() {
    final path = _routeInformationProvider?.value.uri.path ?? '';
    final isHome = path == Destinations.home ||
        path.startsWith('${Destinations.home}/');
    if (_isHomeRouteActive == isHome) return;

    _isHomeRouteActive = isHome;
    if (!_isHomeRouteActive) {
      _autoAdvanceTimer?.cancel();
      _cancelTrailerPreview();
      return;
    }

    if (_activeTrailerItemId != null) {
      _cancelTrailerPreview();
    }

    _startAutoAdvance();
    final items = widget.viewModel.items;
    if (_currentIndex < items.length) {
      _scheduleTrailerPreview(items[_currentIndex]);
    }
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    if (!widget.prefs.get(UserPreferences.mediaBarAutoAdvance)) return;
    if (widget.externallyPaused) return;
    if (_isTrailerPlaying) return;
    if (!_isHomeRouteActive) return;
    final intervalMs = widget.prefs.get(UserPreferences.mediaBarIntervalMs);
    _autoAdvanceTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) {
        if (_isPaused ||
            _isTrailerPlaying ||
            !mounted ||
            widget.externallyPaused ||
            !_isHomeRouteActive) {
          return;
        }
        final items = widget.viewModel.items;
        if (items.isEmpty) return;
        final nextIndex = (_currentIndex + 1) % items.length;
        _goToPage(nextIndex);
      },
    );
  }

  void _goToPage(int index) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _startAutoAdvance();
    _cancelTrailerPreview();
    final items = widget.viewModel.items;
    if (index < items.length) {
      _scheduleTrailerPreview(items[index]);
    }
  }

  void _setPaused(bool paused) {
    if (_isPaused == paused) return;
    _isPaused = paused;
    if (paused) {
      _autoAdvanceTimer?.cancel();
    } else {
      _startAutoAdvance();
    }
  }

  void _scheduleTrailerPreview(MediaBarSlideItem item) {
    if (!widget.prefs.get(UserPreferences.mediaBarTrailerPreview)) return;
    if (!_isHomeRouteActive) return;
    if (_activeTrailerItemId == item.itemId && _trailerVideoOpacity > 0) return;

    _trailerRevealTimer?.cancel();
    final resolveId = ++_trailerResolveId;
    _trailerRevealArmed = false;
    unawaited(_prepareTrailerPreview(item, resolveId));
    _trailerRevealTimer = Timer(_previewRevealDelay, () async {
      if (!mounted || resolveId != _trailerResolveId) return;
      if (!widget.prefs.get(UserPreferences.mediaBarTrailerPreview)) return;
      _trailerRevealArmed = true;
      await _tryRevealPreparedTrailer(item, resolveId);
    });
  }

  void _cancelTrailerPreview() {
    final wasTrailerPlaying = _isTrailerPlaying;
    _trailerRevealTimer?.cancel();
    _trailerResolveId++;
    _trailerRevealArmed = false;
    _isTrailerPlaying = false;
    _trailerPlayer?.stop();
    _activeTrailerItemId = null;
    if (_trailerVideoOpacity != 0.0) {
      setState(() => _trailerVideoOpacity = 0.0);
    }
    if (wasTrailerPlaying) {
      _startAutoAdvance();
    }
  }

  Future<void> _prepareTrailerPreview(
      MediaBarSlideItem item, int resolveId) async {
    final client = _clientForServer(item.serverId);
    String? streamUrl;
    bool useYouTubeHeaders = false;

    try {
      final trailers = await client.itemsApi.getLocalTrailers(item.itemId);
      if (!mounted || resolveId != _trailerResolveId) return;

      final trailerId = _firstItemId(trailers);
      if (trailerId != null) {
        streamUrl = _buildLocalTrailerUrl(client, trailerId);
      }
    } catch (_) {}

    List<Map<String, dynamic>> remoteTrailers = item.remoteTrailers;
    if (remoteTrailers.isEmpty) {
      try {
        final fullItem = await client.itemsApi.getItem(item.itemId);
        if (!mounted || resolveId != _trailerResolveId) return;
        remoteTrailers = (fullItem['RemoteTrailers'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            const [];
      } catch (_) {}
    }

    if (streamUrl == null && remoteTrailers.isNotEmpty) {
      for (final trailer in remoteTrailers) {
        final url = trailer['Url'] as String?;
        if (url == null) continue;
        streamUrl = await YouTubeStreamResolver.resolveFromUrl(url);
        if (streamUrl != null) {
          useYouTubeHeaders =
              YouTubeStreamResolver.extractVideoId(url) != null;
        }
        if (!mounted || resolveId != _trailerResolveId) return;
        if (streamUrl != null) break;
      }
    }

    if (streamUrl == null || !mounted || resolveId != _trailerResolveId) return;

    try {
      final player = _ensureTrailerPlayer();
      await player.setVolume(0);
      if (!mounted || resolveId != _trailerResolveId) return;

      final media = useYouTubeHeaders
          ? Media(streamUrl, httpHeaders: YouTubeStreamResolver.youtubeHeaders)
          : Media(streamUrl);
      await player.open(media).timeout(_openTimeout);
      if (!mounted || resolveId != _trailerResolveId) return;

      setState(() {
        _activeTrailerItemId = item.itemId;
        _trailerVideoOpacity = 0;
      });
      await _tryRevealPreparedTrailer(item, resolveId);
    } catch (_) {
      if (mounted) _cancelTrailerPreview();
    }
  }

  Future<void> _tryRevealPreparedTrailer(
      MediaBarSlideItem item, int resolveId) async {
    if (!mounted || resolveId != _trailerResolveId) return;
    if (!_trailerRevealArmed) return;
    if (_activeTrailerItemId != item.itemId) return;
    if (widget.externallyPaused) return;
    if (!_isHomeRouteActive) return;

    final player = _trailerPlayer;
    if (player == null) return;

    final audioEnabled = widget.prefs.get(UserPreferences.previewAudioEnabled);
    await player.setVolume(audioEnabled ? 100 : 0);
    if (!mounted || resolveId != _trailerResolveId) return;

    await player.play();
    if (!mounted || resolveId != _trailerResolveId) return;

    _isTrailerPlaying = true;
    _autoAdvanceTimer?.cancel();

    if (_trailerVideoOpacity != 1) {
      setState(() => _trailerVideoOpacity = 1);
    }
  }

  Player _ensureTrailerPlayer() {
    final existing = _trailerPlayer;
    if (existing != null) return existing;

    final player = Player(
      configuration: const PlayerConfiguration(libass: false),
    );
    _trailerPlayer = player;
    _trailerCompletedSub = player.stream.completed.listen(_onTrailerCompleted);
    _trailerController = VideoController(
      player,
      configuration: VideoControllerConfiguration(
        hwdec: PlatformDetection.isLinux && !PlatformDetection.isLinuxWayland
            ? 'no'
            : null,
      ),
    );
    return player;
  }

  void _onTrailerCompleted(bool completed) {
    if (!completed || !mounted) return;
    if (!_isTrailerPlaying || _activeTrailerItemId == null) return;

    _cancelTrailerPreview();

    if (!_isHomeRouteActive || widget.externallyPaused || _isPaused) return;
    final items = widget.viewModel.items;
    if (items.length <= 1) return;

    final nextIndex = (_currentIndex + 1) % items.length;
    _goToPage(nextIndex);
  }

  MediaServerClient _clientForServer(String serverId) {
    final active = GetIt.instance<MediaServerClient>();
    if (active.baseUrl == serverId || serverId.isEmpty) {
      return active;
    }
    final factory = GetIt.instance<MediaServerClientFactory>();
    return factory.getClientIfExists(serverId) ?? active;
  }

  String? _firstItemId(List<Map<String, dynamic>> items) {
    for (final item in items) {
      final id = item['Id'] as String?;
      if (id != null && id.isNotEmpty) {
        return id;
      }
    }
    return null;
  }

  String _buildLocalTrailerUrl(MediaServerClient client, String trailerId) {
    final params = <String, String>{
      'Static': 'false',
      'videoCodec': 'h264',
      'audioCodec': 'aac',
      'maxVideoBitDepth': '8',
      'audioBitRate': '128000',
      'audioChannels': '2',
      'subtitleMethod': 'Drop',
      if (client.accessToken != null) 'ApiKey': client.accessToken!,
    };
    return Uri.parse('${client.baseUrl}/Videos/$trailerId/stream')
        .replace(queryParameters: params)
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = widget.viewModel.state;

    return switch (state) {
      MediaBarLoading() => _buildStatusPanel(
          context,
          title: l10n.mediaBarLoading,
        ),
      MediaBarDisabled() => const SizedBox.shrink(),
      MediaBarError(message: final message) => _buildStatusPanel(
          context,
          title: l10n.mediaBarError,
          detail: message,
          showRetry: true,
        ),
      MediaBarReady(items: final items) => items.isEmpty
          ? const SizedBox.shrink()
          : _buildSlideshow(context, items),
    };
  }

  Widget _buildStatusPanel(
    BuildContext context, {
    required String title,
    String? detail,
    bool showRetry = false,
  }) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.slideshow, color: Colors.white70),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      if (detail != null && detail.isNotEmpty)
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
                if (showRetry)
                  TextButton(
                    onPressed: () => widget.viewModel.load(context: context),
                    child: Text(AppLocalizations.of(context).retry),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlideshow(BuildContext context, List<MediaBarSlideItem> items) {
    const overlayColor = Colors.black;
    const overlayOpacity = 0.7;
    final currentItem = items.elementAtOrNull(_currentIndex);
    
    final isMobile = PlatformDetection.useMobileUi;
    final isTablet = isMobile && MediaQuery.of(context).size.shortestSide >= 600;
    final navbarAtTop = isMobile && 
        (GetIt.instance<UserPreferences>().get(UserPreferences.navbarPosition) == NavbarPosition.top);
    final toolbarInset = navbarAtTop ? MediaQuery.of(context).padding.top + 60.0 : 0.0;

    return MouseRegion(
      onEnter: (_) => _setPaused(true),
      onExit: (_) => _setPaused(false),
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        onFocusChange: (focused) => _setPaused(focused),
        onKeyEvent: (node, event) => _handleKeyEvent(event, items),
        child: GestureDetector(
          onTap: () => _navigateToItem(context, items),
          child: Padding(
            padding: EdgeInsets.only(top: toolbarInset),
            child: SizedBox(
              height: widget.height - toolbarInset,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                AnimatedOpacity(
                  opacity: PlatformDetection.isLinux && _trailerVideoOpacity > 0
                      ? 0
                      : 1,
                  duration: const Duration(milliseconds: 250),
                  child: _BackdropLayer(
                    items: items,
                    pageController: _pageController,
                    onPageChanged: _onPageChanged,
                  ),
                ),
                if (_trailerController != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _trailerVideoOpacity,
                        duration: const Duration(milliseconds: 800),
                        child: Video(
                          controller: _trailerController!,
                          controls: NoVideoControls,
                          fit: BoxFit.cover,
                          pauseUponEnteringBackgroundMode: false,
                          fill: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                _GradientOverlay(
                  color: overlayColor,
                  opacity: overlayOpacity,
                ),
                if (items.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: _IndicatorDots(
                      count: items.length,
                      current: _currentIndex,
                      overlayColor: overlayColor,
                      overlayOpacity: overlayOpacity,
                    ),
                  ),
                if (currentItem != null && currentItem.logoUrl != null && (!isMobile || isTablet))
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 56,
                    left: 16,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: SizedBox(
                        key: ValueKey('logo_${currentItem.itemId}'),
                        width: 280,
                        height: 120,
                        child: _buildLogoWithShadow(currentItem.logoUrl!),
                      ),
                    ),
                  ),
                if (currentItem != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      behavior: PlatformDetection.useMobileUi
                          ? HitTestBehavior.translucent
                          : HitTestBehavior.deferToChild,
                      onHorizontalDragEnd: PlatformDetection.useMobileUi
                          ? (details) {
                              final velocity = details.primaryVelocity ?? 0;
                              if (velocity < -300 && _currentIndex < items.length - 1) {
                                _goToPage(_currentIndex + 1);
                              } else if (velocity > 300 && _currentIndex > 0) {
                                _goToPage(_currentIndex - 1);
                              }
                            }
                          : null,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          key: ValueKey(currentItem.itemId),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isMobile && !isTablet && currentItem.logoUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 16, bottom: 8),
                                child: SizedBox(
                                  width: 180,
                                  height: 70,
                                  child: _buildLogoWithShadow(currentItem.logoUrl!),
                                ),
                              ),
                            _SlideInfo(
                              item: currentItem,
                              ratings: widget.viewModel.ratingsFor(currentItem.itemId),
                              enableAdditionalRatings: widget.prefs.get(
                                UserPreferences.enableAdditionalRatings,
                              ),
                              enabledRatings: widget.prefs.get(UserPreferences.enabledRatings),
                              blockedRatings: widget.prefs.get(UserPreferences.blockedRatings),
                              showLabels: widget.prefs.get(UserPreferences.showRatingLabels),
                              showBadges: widget.prefs.get(UserPreferences.showRatingBadges),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (items.length > 1 && !PlatformDetection.useMobileUi) ...[
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _NavArrow(
                        icon: Icons.chevron_left,
                        onTap: _currentIndex > 0
                            ? () => _goToPage(_currentIndex - 1)
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _NavArrow(
                        icon: Icons.chevron_right,
                        onTap: _currentIndex < items.length - 1
                            ? () => _goToPage(_currentIndex + 1)
                            : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(
    KeyEvent event,
    List<MediaBarSlideItem> items,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowLeft) {
      if (_currentIndex > 0) _goToPage(_currentIndex - 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      if (_currentIndex < items.length - 1) _goToPage(_currentIndex + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      _navigateToItem(context, items);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _navigateToItem(BuildContext context, List<MediaBarSlideItem> items) {
    final item = items.elementAtOrNull(_currentIndex);
    if (item != null) {
      _cancelTrailerPreview();
      context.push(Destinations.item(item.itemId, serverId: item.serverId));
    }
  }

  Widget _buildLogoWithShadow(String url) {
    Widget image() => CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      alignment: Alignment.centerLeft,
      fadeInDuration: Duration.zero,
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 2,
          bottom: -2,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.4),
                BlendMode.srcATop,
              ),
              child: image(),
            ),
          ),
        ),
        image(),
      ],
    );
  }
}

class _BackdropLayer extends StatelessWidget {
  final List<MediaBarSlideItem> items;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  const _BackdropLayer({
    required this.items,
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      onPageChanged: onPageChanged,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.backdropUrl == null) {
          return const ColoredBox(color: Colors.black);
        }
        return CachedNetworkImage(
          imageUrl: item.backdropUrl!,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 300),
          errorWidget: (_, __, ___) =>
              const ColoredBox(color: Colors.black),
        );
      },
    );
  }
}

class _GradientOverlay extends StatelessWidget {
  final Color color;
  final double opacity;

  const _GradientOverlay({required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: opacity * 0.3),
              color.withValues(alpha: opacity * 0.1),
              color.withValues(alpha: opacity * 0.8),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavArrow({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          canRequestFocus: false,
          customBorder: const CircleBorder(),
          child: AnimatedOpacity(
            opacity: onTap != null ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.4),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.9),
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideInfo extends StatelessWidget {
  final MediaBarSlideItem item;
  final Map<String, double> ratings;
  final bool enableAdditionalRatings;
  final String enabledRatings;
  final String blockedRatings;
  final bool showLabels;
  final bool showBadges;

  const _SlideInfo({
    required this.item,
    required this.ratings,
    required this.enableAdditionalRatings,
    required this.enabledRatings,
    required this.blockedRatings,
    this.showLabels = true,
    this.showBadges = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = PlatformDetection.useMobileUi;

    return Padding(
      padding: EdgeInsets.only(left: 8, right: 8, bottom: isMobile ? 24 : 36),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _MetadataRow(item: item),
                if (ratings.isNotEmpty || item.communityRating != null) ...[
                  const SizedBox(height: 6),
                  RatingsRow(
                    ratings: ratings,
                    communityRating: item.communityRating,
                    criticRating: item.criticRating,
                    enableAdditionalRatings: enableAdditionalRatings,
                    enabledRatings: enabledRatings,
                    blockedRatings: blockedRatings,
                    showLabels: showLabels,
                    showBadges: showBadges,
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  height: ((isMobile
                          ? theme.textTheme.bodySmall?.fontSize
                          : theme.textTheme.bodyMedium?.fontSize) ??
                      14) *
                      1.4 *
                      (isMobile ? 2 : 3),
                  child: Text(
                    item.overview ?? '',
                    style: (isMobile
                            ? theme.textTheme.bodySmall
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      shadows: _textShadows,
                    ),
                    maxLines: isMobile ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final MediaBarSlideItem item;

  const _MetadataRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <Widget>[];

    if (item.year != null) {
      parts.add(_infoText(theme, item.year.toString()));
    }

    if (item.officialRating != null) {
      parts.add(_ratingBadge(theme, item.officialRating!));
    }

    if (item.itemType != 'Series' && item.runtime != null) {
      final h = item.runtime!.inHours;
      final m = item.runtime!.inMinutes.remainder(60);
      parts.add(_infoText(theme, h > 0 ? '${h}h ${m}m' : '${m}m'));
    }

    if (item.genres.isNotEmpty) {
      parts.add(_infoText(theme, item.genres.join(' \u2022 ')));
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

  Widget _infoText(ThemeData theme, String value) {
    return Text(
      value,
      style: theme.textTheme.bodySmall?.copyWith(
        color: Colors.white.withValues(alpha: 0.9),
        fontWeight: FontWeight.w600,
        shadows: _textShadows,
      ),
    );
  }

  Widget _ratingBadge(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(3),
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
}

class _IndicatorDots extends StatelessWidget {
  final int count;
  final int current;
  final Color overlayColor;
  final double overlayOpacity;

  const _IndicatorDots({
    required this.count,
    required this.current,
    required this.overlayColor,
    required this.overlayOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: overlayColor.withValues(alpha: overlayOpacity * 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(count, (i) {
            final isActive = i == current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 10 : 8,
              height: isActive ? 10 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
              ),
            );
          }),
        ),
      ),
    );
  }
}
