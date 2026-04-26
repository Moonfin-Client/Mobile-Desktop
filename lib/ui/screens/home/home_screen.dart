import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:server_core/server_core.dart' hide ImageType;

import '../../../data/models/aggregated_item.dart';
import '../../../data/models/home_row.dart';
import '../../../data/services/background_service.dart';
import '../../../data/services/theme_music_service.dart';
import '../../../data/services/media_server_client_factory.dart';
import '../../../l10n/app_localizations.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../widgets/exit_confirmation_dialog.dart';
import '../../../util/app_exit.dart';
import '../../widgets/focus/context_menu_sheet.dart';
import '../../widgets/focus/locked_focus_row.dart';
import '../../../util/focus/dpad_keys.dart';
import '../../../util/platform_detection.dart';
import '../../../util/server_url.dart';
import '../../navigation/app_router.dart';
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
import '../../widgets/settings/settings_panel.dart';
import '../../navigation/home_refresh_bus.dart';
import '../../widgets/bounded_network_image.dart';
import '../../widgets/fullscreen_backdrop_switcher.dart';
import 'home_view_model.dart';

const _homeBackground = Color(0xFF101528);

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

class _HomeShellState extends State<_HomeShell> with WidgetsBindingObserver {
  final _backgroundService = GetIt.instance<BackgroundService>();
  final _userPrefs = GetIt.instance<UserPreferences>();
  final _themeMusicService = GetIt.instance<ThemeMusicService>();
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
  Type? _lastMediaBarStateRuntime;
  int _lastMediaBarItemCount = 0;
  bool _lastMultiServer = false;
  String _lastBlockedParentalRatings = '';
  bool _themeMusicRegistered = false;
  String? _lastObservedPath;

  static const _selectionDelay = Duration(milliseconds: 150);
  static const _backdropDelay = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appRouter.routerDelegate.addListener(_onRouteChanged);
    _lastObservedPath = appRouter.routerDelegate.currentConfiguration.uri.path;
    homeRefreshBus.addListener(_onHomeRefreshRequested);
    if (consumePendingHomeRefresh()) {
      _viewModel.refresh(preserveExisting: true);
    }
    _backgroundSub = _backgroundService.backgroundStream.listen((url) {
      if (mounted) setState(() => _backdropUrl = url);
    });
    _backdropUrl = _backgroundService.currentUrl;

    _viewModel = GetIt.instance<HomeViewModel>();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.mediaBarViewModel.addListener(_onMediaBarStateChanged);
    _lastMediaBarStateRuntime = _viewModel.mediaBarViewModel.state.runtimeType;
    _lastMediaBarItemCount =
        _viewModel.mediaBarViewModel.state is MediaBarReady
            ? (_viewModel.mediaBarViewModel.state as MediaBarReady).items.length
            : 0;
    _lastSectionsJson = _userPrefs.get(UserPreferences.homeSectionsJson);
    _lastMultiServer = _userPrefs.get(UserPreferences.enableMultiServerLibraries);
    _lastBlockedParentalRatings = _userPrefs.get(UserPreferences.blockedParentalRatings);
    _userPrefs.addListener(_onPrefsChanged);
    _maybeRegisterThemeMusic();
    _viewModel.load();
  }

  @override
  void dispose() {
    appRouter.routerDelegate.removeListener(_onRouteChanged);
    homeRefreshBus.removeListener(_onHomeRefreshRequested);
    WidgetsBinding.instance.removeObserver(this);
    _selectionDebounce?.cancel();
    _backdropDebounce?.cancel();
    _hoverPauseTimer?.cancel();
    _backgroundSub?.cancel();
    _viewModel.mediaBarViewModel.removeListener(_onMediaBarStateChanged);
    _viewModel.removeListener(_onViewModelChanged);
    _userPrefs.removeListener(_onPrefsChanged);
    if (_themeMusicRegistered) {
      _themeMusicService.unregisterDetailScreen(this);
      _themeMusicRegistered = false;
    }
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  void _onMediaBarStateChanged() {
    if (!mounted) return;
    final state = _viewModel.mediaBarViewModel.state;
    final runtime = state.runtimeType;
    final itemCount = state is MediaBarReady ? state.items.length : 0;
    if (runtime == _lastMediaBarStateRuntime &&
        itemCount == _lastMediaBarItemCount) {
      return;
    }
    _lastMediaBarStateRuntime = runtime;
    _lastMediaBarItemCount = itemCount;
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _viewModel.refresh(preserveExisting: true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _themeMusicService.fadeOutAndStop();
    }
  }

  void _onHomeRefreshRequested() {
    if (!mounted) return;
    _viewModel.refresh(preserveExisting: true);
  }

  void _onPrefsChanged() {
    if (!mounted) return;
    final currentJson = _userPrefs.get(UserPreferences.homeSectionsJson);
    final currentMultiServer = _userPrefs.get(UserPreferences.enableMultiServerLibraries);
    final currentBlocked = _userPrefs.get(UserPreferences.blockedParentalRatings);
    if (currentJson != _lastSectionsJson ||
        currentMultiServer != _lastMultiServer ||
        currentBlocked != _lastBlockedParentalRatings) {
      _lastSectionsJson = currentJson;
      _lastMultiServer = currentMultiServer;
      _lastBlockedParentalRatings = currentBlocked;
      _viewModel.refresh();
    }
    _maybeRegisterThemeMusic();
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

      _maybePlayThemeMusic(item);
    });
  }

  void _maybeRegisterThemeMusic() {
    final shouldRegister =
        _userPrefs.get(UserPreferences.themeMusicEnabled) &&
            _userPrefs.get(UserPreferences.themeMusicOnHomeRows);
    if (shouldRegister && !_themeMusicRegistered) {
      _themeMusicService.registerDetailScreen(this);
      _themeMusicRegistered = true;
    } else if (!shouldRegister && _themeMusicRegistered) {
      _themeMusicService.unregisterDetailScreen(this);
      _themeMusicRegistered = false;
    }
  }

  void _maybePlayThemeMusic(AggregatedItem? item) {
    _maybeRegisterThemeMusic();
    if (!_isHomeRouteActive()) {
      _themeMusicService.fadeOutAndStop();
      return;
    }
    if (!_themeMusicRegistered) {
      _themeMusicService.fadeOutAndStop();
      return;
    }
    if (item == null) {
      _themeMusicService.fadeOutAndStop();
      return;
    }
    _themeMusicService.playForItem(item);
  }

  bool _isHomeRouteActive() {
    final path = appRouter.routerDelegate.currentConfiguration.uri.path;
    return path == Destinations.home || path.startsWith('${Destinations.home}/');
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final path = appRouter.routerDelegate.currentConfiguration.uri.path;
    if (path == _lastObservedPath) return;
    _lastObservedPath = path;

    final onHome = _isHomeRouteActive();
    if (!onHome) {
      if (_themeMusicRegistered) {
        _themeMusicService.unregisterDetailScreen(this);
        _themeMusicRegistered = false;
      }
      _themeMusicService.fadeOutAndStop();
      return;
    }

    _maybeRegisterThemeMusic();
    if (_selectedItem != null) {
      _maybePlayThemeMusic(_selectedItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backdropEnabled = _userPrefs.get(UserPreferences.backdropEnabled);
    final blurAmount = _userPrefs.get(UserPreferences.browsingBackgroundBlurAmount).toDouble();
    final seasonalEffect = _userPrefs.get(UserPreferences.seasonalSurprise);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showExitConfirmation(context);
      },
      child: Scaffold(
        backgroundColor: _homeBackground,
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
    if (!_userPrefs.get(UserPreferences.confirmExit)) {
      await AppExit.closeApp();
      return;
    }
    final navContext = appRouter.routerDelegate.navigatorKey.currentContext;
    await showExitConfirmationDialog(navContext ?? context);
  }
}

class _Backdrop extends StatelessWidget {
  final String? url;
  final double blurAmount;

  const _Backdrop({this.url, required this.blurAmount});

  @override
  Widget build(BuildContext context) {
    return FullscreenBackdropSwitcher(
      imageUrl: url,
      duration: BackgroundService.transitionDuration,
      imageBuilder: (imageUrl) => _blurredImage(imageUrl, blurAmount),
    );
  }

  Widget _blurredImage(String imageUrl, double blur) {
    final image = BoundedNetworkImage(
      imageUrl: imageUrl,
      scale: blur > 0 ? 0.3 : 1.0,
      minWidth: 320,
      maxWidth: blur > 0 ? 640 : 1280,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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

class _ContentRowsState extends State<_ContentRows>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  final _mediaBarFocusNode = FocusNode(debugLabel: 'home_media_bar_focus');
  final _themeMusicService = GetIt.instance<ThemeMusicService>();
  final Map<int, GlobalKey> _rowKeys = {};
  final Map<int, GlobalKey> _rowContainerKeys = {};
  int? _activeFocusedRowIndex;
  Timer? _previewDelayTimer;
  Timer? _previewStopTimer;
  Player? _previewPlayer;
  VideoController? _previewController;
  int _previewRequestId = 0;
  bool _previewReady = false;
  double _scrollOffset = 0;
  double _previewStartScrollOffset = 0;
  bool _isScrolledToTop = true;
  bool _isActivelyScrolling = false;
  Timer? _scrollIdleTimer;
  bool _infoRevealed = false;
  bool _mediaBarVisible = true;
  bool _initialFocusResolved = false;
  String? _lastObservedPath;
  bool _suppressNextRowPreviewFromMediaBar = false;
  bool _forceRevealOnNextRowFocusFromMediaBar = false;
  DateTime? _lastScrollTime;
  DateTime? _lastVerticalNavAt;
  bool _verticalNavInFlight = false;
  bool _chromeFocusActive = false;
  String? _activePreviewKey;
  List<double> _rowTopOffsets = [];
  double _overlayBottom = 0;
  static const _previewScrollThreshold = 150.0;
  static const _pinTransitionDistance = 96.0;
  static const _previewStartDelay = Duration(milliseconds: 1200);
  static const _focusHandoffDuration = Duration(milliseconds: 220);
  static const _focusHandoffCurve = Curves.easeInOutCubic;
  static const _mediaBarFadeDuration = Duration(milliseconds: 220);

  void _markUserGesture() {
    if (!kIsWeb) return;
    if (!widget.prefs.get(UserPreferences.previewAudioEnabled)) return;
    final player = _previewPlayer;
    if (player == null || _activePreviewKey == null) return;
    unawaited(player.setVolume(100.0));
  }

  int? _focusedRowIndex(FocusNode? node) {
    if (node == null) return null;
    if (identical(node, _mediaBarFocusNode)) return null;
    return _activeFocusedRowIndex;
  }

  void _onGlobalFocusChanged() {
    if (!mounted) return;
    final primary = FocusManager.instance.primaryFocus;
    final onMediaBar = identical(primary, _mediaBarFocusNode);
    final chromeFocusActive =
        SettingsPanel.isOpenNotifier.value ||
        (!onMediaBar && _activeFocusedRowIndex == null);

    final nextMediaBarVisible = onMediaBar || _activeFocusedRowIndex == null;
    final chromeChanged = _chromeFocusActive != chromeFocusActive;

    if (_mediaBarVisible != nextMediaBarVisible || chromeChanged) {
      setState(() {
        _mediaBarVisible = nextMediaBarVisible;
        _chromeFocusActive = chromeFocusActive;
      });
    }

    if (chromeFocusActive && (chromeChanged || _activePreviewKey != null)) {
      _finishSharedPreview(releaseResources: true);
    }
  }

  void _onSettingsPanelOpenChanged() {
    _onGlobalFocusChanged();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
    appRouter.routerDelegate.addListener(_onRouteChanged);
    FocusManager.instance.addListener(_onGlobalFocusChanged);
    SettingsPanel.isOpenNotifier.addListener(_onSettingsPanelOpenChanged);
    if (!widget.prefs.get(UserPreferences.mediaBarEnabled)) {
      _infoRevealed = true;
    }
  }

  @override
  void dispose() {
    appRouter.routerDelegate.removeListener(_onRouteChanged);
    WidgetsBinding.instance.removeObserver(this);
    FocusManager.instance.removeListener(_onGlobalFocusChanged);
    SettingsPanel.isOpenNotifier.removeListener(_onSettingsPanelOpenChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollIdleTimer?.cancel();
    _mediaBarFocusNode.dispose();
    _rowKeys.clear();
    _disposeSharedPreview();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _finishSharedPreview(releaseResources: true);
    }
  }

  void _onRouteChanged() {
    final path = appRouter.routerDelegate.currentConfiguration.uri.path;
    final wasOnHome = _lastObservedPath?.startsWith(Destinations.home) ?? false;
    _lastObservedPath = path;

    if (!path.startsWith(Destinations.home)) {
      _finishSharedPreview(releaseResources: true);
      return;
    }

    // Only reset initial focus when entering home from a non-home route
    // (e.g. login, server select). Pop-back from /item should keep the
    // user's previous focus in place.
    if (!wasOnHome) {
      _initialFocusResolved = false;
    }
  }

  static bool _supportsEpisodePreview(AggregatedItem item) {
    return item.type == 'Series' ||
        item.type == 'Movie' ||
        item.type == 'Episode' ||
        item.type == 'Video' ||
        item.type == 'MusicVideo';
  }

  static String _previewKeyFor(AggregatedItem item) {
    return '${item.serverId}:${item.id}';
  }

  MediaServerClient? _clientForItem(AggregatedItem item) {
    final factory = GetIt.instance<MediaServerClientFactory>();
    final fromFactory = factory.getClientIfExists(item.serverId);
    if (fromFactory != null) {
      return fromFactory;
    }

    final active = GetIt.instance<MediaServerClient>();
    final normalizedActive = normalizeServerBaseUrl(active.baseUrl);
    final normalizedServerId = normalizeServerBaseUrl(item.serverId);
    if (normalizedActive.isNotEmpty &&
        normalizedServerId.isNotEmpty &&
        normalizedActive == normalizedServerId) {
      return active;
    }

    return null;
  }

  void _schedulePreview(AggregatedItem item, {required Duration delay}) {
    if (!widget.prefs.get(UserPreferences.episodePreviewEnabled) ||
        !_supportsEpisodePreview(item) ||
        _chromeFocusActive) {
      return;
    }

    final previewKey = _previewKeyFor(item);
    if (_activePreviewKey == previewKey) return;

    if (_activePreviewKey != null) {
      _finishSharedPreview();
    }

    _previewDelayTimer?.cancel();
    _previewDelayTimer = Timer(delay, () async {
      if (!mounted) {
        return;
      }

      _previewStartScrollOffset = _scrollController.offset;
      setState(() {
        _activePreviewKey = previewKey;
        _previewReady = false;
      });
      await _startSharedPreview(item, previewKey);
    });
  }

  void _stopPreviewFor(AggregatedItem item) {
    final previewKey = _previewKeyFor(item);
    _previewDelayTimer?.cancel();
    if (_activePreviewKey == previewKey && mounted) {
      _finishSharedPreview();
    }
  }

  void _finishSharedPreview({
    bool releaseResources = false,
    bool updateUi = true,
  }) {
    _previewDelayTimer?.cancel();
    _previewStopTimer?.cancel();
    _previewRequestId++;
    if (!kIsWeb) {
      _previewPlayer?.stop();
    }
    if (releaseResources || kIsWeb) {
      _previewPlayer?.dispose();
      _previewPlayer = null;
      _previewController = null;
    }

    if (_activePreviewKey != null || _previewReady) {
      if (updateUi && mounted) {
        setState(() {
          _activePreviewKey = null;
          _previewReady = false;
        });
      } else {
        _activePreviewKey = null;
        _previewReady = false;
      }
    }
    _themeMusicService.setExternalAudioActive(false);
  }

  void _disposeSharedPreview() {
    _finishSharedPreview(releaseResources: true, updateUi: false);
  }

  Future<void> _startSharedPreview(AggregatedItem item, String previewKey) async {
    if (_chromeFocusActive) {
      _finishSharedPreview(releaseResources: true);
      return;
    }
    final requestId = ++_previewRequestId;

    _previewStopTimer?.cancel();
    if (kIsWeb) {
      _previewPlayer?.dispose();
      _previewPlayer = null;
      _previewController = null;
    } else {
      _previewPlayer?.stop();
    }
    _themeMusicService.setExternalAudioActive(true);

    try {
      final client = _clientForItem(item);
      if (client == null) {
        _finishSharedPreview();
        return;
      }
      final target = await _resolvePreviewTargetItem(client, item);
      if (!mounted || target == null || requestId != _previewRequestId || _activePreviewKey != previewKey) {
        return;
      }

      final player = _ensureSharedPreviewPlayer();
      final seekPosition = _previewSeekPosition(target);

      final previewAudioEnabled = widget.prefs.get(
        UserPreferences.previewAudioEnabled,
      );
      final previewVolume = kIsWeb
          ? 0.0
          : (previewAudioEnabled ? 100.0 : 0.0);
      await player.setVolume(previewVolume);
      if (!mounted || requestId != _previewRequestId || _activePreviewKey != previewKey) {
        return;
      }

      final previewUrl = _buildPreviewUrl(client, target, seekPosition);
      final previewUri = Uri.tryParse(previewUrl);
      if (previewUri == null ||
          !previewUri.hasScheme ||
          previewUri.host.isEmpty) {
        _finishSharedPreview();
        return;
      }

      await player.open(Media(previewUrl));
      if (!mounted || requestId != _previewRequestId || _activePreviewKey != previewKey) {
        return;
      }

      if (previewAudioEnabled) {
        await player.setVolume(100.0);
        if (!mounted || requestId != _previewRequestId || _activePreviewKey != previewKey) {
          return;
        }
      }

      await player.setPlaylistMode(PlaylistMode.loop);
      if (!mounted || requestId != _previewRequestId || _activePreviewKey != previewKey) {
        return;
      }

      _previewStopTimer = Timer(const Duration(seconds: 30), () {
        if (requestId == _previewRequestId && _activePreviewKey == previewKey) {
          _finishSharedPreview();
        }
      });

      if (mounted && requestId == _previewRequestId && _activePreviewKey == previewKey) {
        setState(() => _previewReady = true);
      }
    } catch (_) {
      if (mounted && requestId == _previewRequestId && _activePreviewKey == previewKey) {
        _finishSharedPreview();
      }
    }
  }

  Player _ensureSharedPreviewPlayer() {
    final existing = _previewPlayer;
    if (existing != null) {
      return existing;
    }

    final player = Player(
      configuration: const PlayerConfiguration(
        libass: false,
      ),
    );
    final platform = player.platform;
    if (platform is NativePlayer) {
      try {
        final dynamic native = platform;
        native.setProperty('network-timeout', '30');
      } catch (_) {}
    }
    _previewPlayer = player;
    _previewController = VideoController(
      player,
      configuration: VideoControllerConfiguration(
        hwdec: _homePreviewHwdecSetting(),
      ),
    );
    return player;
  }

  String? _homePreviewHwdecSetting() {
    final hwDecodingEnabled = widget.prefs.get(UserPreferences.hardwareDecoding);
    if (!hwDecodingEnabled) {
      return 'no';
    }
    if (PlatformDetection.isAndroid && PlatformDetection.isTV) {
      return 'auto';
    }
    if (PlatformDetection.isLinux) {
      return 'auto-safe';
    }
    return null;
  }

  Future<AggregatedItem?> _resolvePreviewTargetItem(
    MediaServerClient client,
    AggregatedItem item,
  ) async {
    try {
      String targetId = item.id;
      Map<String, dynamic> fallbackRawData = item.rawData;

      if (item.type == 'Series') {
        final seasonsData = await client.itemsApi.getSeasons(item.id);
        final seasons = (seasonsData['Items'] as List?)
                ?.cast<Map<String, dynamic>>()
                .toList() ??
            const <Map<String, dynamic>>[];
        if (seasons.isEmpty) {
          return null;
        }

        seasons.sort((a, b) =>
            ((a['IndexNumber'] as int?) ?? 1 << 20)
                .compareTo((b['IndexNumber'] as int?) ?? 1 << 20));

        final firstSeasonId = seasons.first['Id'] as String?;
        if (firstSeasonId == null || firstSeasonId.isEmpty) {
          return null;
        }

        final episodesData = await client.itemsApi.getEpisodes(
          item.id,
          seasonId: firstSeasonId,
        );
        final episodes = (episodesData['Items'] as List?)
                ?.cast<Map<String, dynamic>>()
                .toList() ??
            const <Map<String, dynamic>>[];
        if (episodes.isEmpty) {
          return null;
        }

        episodes.sort((a, b) =>
            ((a['IndexNumber'] as int?) ?? 1 << 20)
                .compareTo((b['IndexNumber'] as int?) ?? 1 << 20));

        final first = episodes.first;
        final firstId = first['Id'] as String?;
        if (firstId == null || firstId.isEmpty) {
          return null;
        }
        targetId = firstId;
        fallbackRawData = first;
      }

      try {
        final itemData = await client.itemsApi.getItem(targetId);
        return AggregatedItem(
          id: targetId,
          serverId: item.serverId,
          rawData: itemData,
        );
      } catch (_) {
        return AggregatedItem(
          id: targetId,
          serverId: item.serverId,
          rawData: fallbackRawData,
        );
      }
    } catch (_) {
      return null;
    }
  }

  Duration _previewSeekPosition(AggregatedItem item) {
    final resume = _playbackPositionFromRaw(item);
    if (resume != null && resume > Duration.zero) {
      return resume;
    }

    return const Duration(minutes: 3);
  }

  Duration? _playbackPositionFromRaw(AggregatedItem item) {
    final userData = item.rawData['UserData'];
    if (userData is! Map) {
      return item.playbackPosition;
    }

    final rawTicks = userData['PlaybackPositionTicks'];
    if (rawTicks is num && rawTicks > 0) {
      return Duration(microseconds: rawTicks.toInt() ~/ 10);
    }

    return item.playbackPosition;
  }

  String _buildPreviewUrl(
    MediaServerClient client,
    AggregatedItem item,
    Duration startPosition,
  ) {
    if (item.id.isEmpty) return '';

    final baseUri = Uri.tryParse(client.baseUrl.trim());
    if (baseUri == null || !baseUri.hasScheme || baseUri.host.isEmpty) {
      return '';
    }

    final mediaSourceId = item.mediaSources.isNotEmpty
        ? item.mediaSources.first['Id'] as String?
        : null;
    final startTicks = startPosition.inMicroseconds * 10;
    final params = <String, String>{
      'Static': 'false',
      'videoCodec': 'h264',
      'audioCodec': 'aac',
      'maxVideoBitDepth': '8',
      'videoBitRate': '4000000',
      'maxWidth': '1280',
      'maxHeight': '720',
      'audioBitRate': '96000',
      'audioChannels': '2',
      'subtitleMethod': 'Drop',
      if (kIsWeb) 'container': 'mp4',
      if (kIsWeb) 'TranscodingContainer': 'mp4',
      if (startTicks > 0) 'StartTimeTicks': '$startTicks',
      if (mediaSourceId != null) 'MediaSourceId': mediaSourceId,
      if (client.accessToken != null) 'ApiKey': client.accessToken!,
    };

      final normalizedBasePath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
      final streamPath = kIsWeb ? 'stream.mp4' : 'stream';
      final fullPath =
        '$normalizedBasePath/Videos/${item.id}/$streamPath';

      return baseUri
        .replace(path: fullPath, queryParameters: params)
        .toString();
  }

  bool _isMediaBarIncluded() {
    if (!widget.prefs.get(UserPreferences.mediaBarEnabled)) {
      return false;
    }

    final mediaBarState = widget.mediaBarViewModel.state;
    return mediaBarState is MediaBarLoading ||
        mediaBarState is MediaBarError ||
        (mediaBarState is MediaBarReady && mediaBarState.items.isNotEmpty);
  }

  bool _isHomeRouteActive() {
    if (!mounted) return false;
    final route = ModalRoute.of(context);
    return route?.isCurrent ?? true;
  }

  double _mediaBarHeight() {
    final size = MediaQuery.sizeOf(context);
    final screenHeight = size.height;
    final screenWidth = size.width;
    
    if (!PlatformDetection.useMobileUi) {
      return screenHeight;
    }

    final isLandscape = screenWidth > screenHeight;
    return isLandscape ? screenHeight : screenHeight * 0.55;
  }

  double _pinnedInfoCollapseOffset() {
    return (_mediaBarHeight() - (_pinTransitionDistance / 2))
        .clamp(0.0, double.infinity);
  }

  Future<void> _revealAndScrollToPinnedInfo({
    bool ignoreScrollCooldown = false,
  }) async {
    if (_infoRevealed) return;
    if (!widget.prefs.get(UserPreferences.homeRowInfoOverlay)) return;

    final now = DateTime.now();
    if (!ignoreScrollCooldown &&
        _lastScrollTime != null &&
        now.difference(_lastScrollTime!).inMilliseconds < 350) {
      return;
    }

    if (mounted) {
      setState(() => _infoRevealed = true);
    }
  }

  void _navigateFromMediaBarToNavbar() {
    if (_scrollController.hasClients && _scrollController.offset > 0) {
      unawaited(_scrollController.animateTo(
        0,
        duration: _focusHandoffDuration,
        curve: _focusHandoffCurve,
      ));
    }
    _requestFocusToNavbar();
  }

  void _requestFocusToNavbar({int attempt = 0}) {
    if (!mounted) return;
    final focusNavbar = NavigationLayout.focusNavbarNotifier.value;
    if (focusNavbar != null) {
      focusNavbar();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final primary = FocusManager.instance.primaryFocus;
        final ctx = primary?.context;
        if (primary != null && ctx != null) {
          final box = ctx.findRenderObject();
          if (box is RenderBox && box.localToGlobal(Offset.zero).dy < 120) {
            return;
          }
        }
        if (attempt < 4) {
          _requestFocusToNavbar(attempt: attempt + 1);
        } else {
          FocusScope.of(context).focusInDirection(TraversalDirection.up);
        }
      });
      return;
    }
    if (attempt < 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _requestFocusToNavbar(attempt: attempt + 1);
      });
    }
  }

  Future<void> _moveFocusFromMediaBarToRows() async {
    if (_verticalNavInFlight || !_allowVerticalNavNow()) {
      return;
    }
    if (!_mediaBarFocusNode.hasFocus) {
      return;
    }

    if (!_isMediaBarIncluded()) {
      FocusScope.of(context).nextFocus();
      return;
    }

    _finishSharedPreview(releaseResources: true);
    _suppressNextRowPreviewFromMediaBar = true;
    _forceRevealOnNextRowFocusFromMediaBar = true;
    if (mounted && _mediaBarVisible) {
      setState(() => _mediaBarVisible = false);
    }
    if (_scrollController.hasClients) {
      final target = _mediaBarHeight()
          .clamp(0.0, _scrollController.position.maxScrollExtent);
      if (_scrollController.offset < target) {
        _scrollController.jumpTo(target);
      }
    }
    await _focusAdjacentRowItem(widget.viewModel.rows, -1, 1);
  }

  void _onHomeRowTileFocused(AggregatedItem? item) {
    final forceReveal = _forceRevealOnNextRowFocusFromMediaBar;
    _forceRevealOnNextRowFocusFromMediaBar = false;
    widget.onItemSelected(item);
    unawaited(_revealAndScrollToPinnedInfo(ignoreScrollCooldown: forceReveal));
    _finishSharedPreview();
    _suppressNextRowPreviewFromMediaBar = false;
  }

  Future<void> _moveFocusFromRowsToMediaBar() async {
    if (_verticalNavInFlight) {
      return;
    }
    _verticalNavInFlight = true;
    try {
      _finishSharedPreview(releaseResources: true);
      widget.onItemSelected(null);
      if (mounted) {
        setState(() {
          _infoRevealed = false;
          _mediaBarVisible = true;
        });
      }
      if (!_isMediaBarIncluded()) {
        _navigateFromMediaBarToNavbar();
        return;
      }

      if (_scrollController.hasClients && _scrollController.offset > 0) {
        await _scrollController.animateTo(
          0,
          duration: _focusHandoffDuration,
          curve: _focusHandoffCurve,
        );
      }

      if (!mounted) return;

      final navComplete = Completer<void>();
      late final VoidCallback focusListener;
      focusListener = () {
        if (_mediaBarFocusNode.hasFocus && !navComplete.isCompleted) {
          navComplete.complete();
        }
      };
      _mediaBarFocusNode.addListener(focusListener);

      _requestMediaBarFocus(force: true);

      if (_mediaBarFocusNode.hasFocus && !navComplete.isCompleted) {
        navComplete.complete();
      }

      await navComplete.future.timeout(
        const Duration(milliseconds: 450),
        onTimeout: () {},
      );
      _mediaBarFocusNode.removeListener(focusListener);
    } finally {
      _verticalNavInFlight = false;
    }
  }

  void _requestMediaBarFocus({int attempt = 0, bool force = false}) {
    if (!mounted || (!force && _initialFocusResolved) || !_isMediaBarIncluded()) {
      return;
    }
    if (!_isHomeRouteActive()) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isMediaBarIncluded()) return;
      if (!_isHomeRouteActive()) return;

      if (_mediaBarFocusNode.context == null) {
        if (attempt < 8) {
          Future<void>.delayed(const Duration(milliseconds: 50), () {
            if (!mounted) return;
            _requestMediaBarFocus(attempt: attempt + 1, force: force);
          });
        }
        return;
      }

      _mediaBarFocusNode.requestFocus();
      if (_mediaBarFocusNode.hasFocus) {
        _initialFocusResolved = true;
        return;
      }

      if (attempt < 8) {
        Future<void>.delayed(const Duration(milliseconds: 50), () {
          if (!mounted) return;
          _requestMediaBarFocus(attempt: attempt + 1, force: force);
        });
      }
    });
  }

  GlobalKey _rowKey(int rowIndex) {
    return _rowKeys.putIfAbsent(rowIndex, () => GlobalKey());
  }

  GlobalKey _rowContainerKey(int rowIndex) {
    return _rowContainerKeys.putIfAbsent(rowIndex, () => GlobalKey());
  }

  LockedFocusRowState? _rowStateOf(int rowIndex) {
    return _rowKeys[rowIndex]?.currentState as LockedFocusRowState?;
  }

  Future<void> _scrollTvRowIntoOverlayBand(int rowIndex) async {
    if (!mounted || !_scrollController.hasClients) return;

    final containerCtx = _rowContainerKeys[rowIndex]?.currentContext;
    final stackRender = context.findRenderObject();
    if (containerCtx == null || stackRender is! RenderBox) {
      return;
    }

    final containerRender = containerCtx.findRenderObject();
    if (containerRender is! RenderBox ||
        !stackRender.hasSize ||
        !containerRender.hasSize) {
      return;
    }

    final stackTopGlobal = stackRender.localToGlobal(Offset.zero).dy;
    final containerTopGlobal = containerRender.localToGlobal(Offset.zero).dy;
    final desiredContainerTopGlobal = stackTopGlobal + _overlayBottom + 8;
    final scrollDelta = containerTopGlobal - desiredContainerTopGlobal;
    final currentOffset = _scrollController.offset;
    final targetOffset = (currentOffset + scrollDelta).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if ((targetOffset - currentOffset).abs() <= 1.0) {
      return;
    }

    await _scrollController.animateTo(
      targetOffset,
      duration: _focusHandoffDuration,
      curve: _focusHandoffCurve,
    );
  }

  void _requestRowFocusFromMemory(int rowIndex, {int? preferredIndex}) {
    final state = _rowStateOf(rowIndex);
    if (state == null) return;
    if (preferredIndex != null) {
      state.requestFocusAt(preferredIndex);
    } else {
      state.requestFocusFromMemory();
    }
  }

  bool _rowHasFocusableItems(HomeRow row) {
    if (row.isLoading) {
      return false;
    }

    return switch (row.rowType) {
      HomeRowType.liveTv => true,
      _ => row.items.isNotEmpty,
    };
  }

  void _ensureInitialHomeFocus(List<HomeRow> rows) {
    if (_initialFocusResolved || !mounted) {
      return;
    }
    if (!_isHomeRouteActive()) return;

    final mediaBarEnabled = widget.prefs.get(UserPreferences.mediaBarEnabled);
    final mediaBarState = widget.mediaBarViewModel.state;
    final firstRowIndex = rows.indexWhere(_rowHasFocusableItems);

    if (firstRowIndex > 0 && rows.take(firstRowIndex).any((r) => r.isLoading)) {
      return;
    }

    bool focusMediaBar = false;
    int? focusRowIndex;

    if (mediaBarEnabled) {
      if (mediaBarState is MediaBarReady) {
        if (mediaBarState.items.isNotEmpty) {
          focusMediaBar = true;
        } else if (firstRowIndex != -1) {
          focusRowIndex = firstRowIndex;
        }
      } else if (mediaBarState is MediaBarDisabled || mediaBarState is MediaBarError) {
        if (firstRowIndex != -1) {
          focusRowIndex = firstRowIndex;
        }
      } else {
        return;
      }
    } else if (firstRowIndex != -1) {
      focusRowIndex = firstRowIndex;
    }

    if (!focusMediaBar && focusRowIndex == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialFocusResolved) {
        return;
      }
      if (!_isHomeRouteActive()) return;

      if (focusMediaBar) {
        if (_scrollController.hasClients && _scrollController.offset > 0) {
          _scrollController.jumpTo(0);
        }
        _requestMediaBarFocus();
        return;
      }

      final rowIndex = focusRowIndex!;
      if (_isMediaBarIncluded() &&
          _scrollController.hasClients &&
          rowIndex >= 0 &&
          rowIndex < _rowTopOffsets.length) {
        final targetOffset = _rowTopOffsets[rowIndex]
            .clamp(0.0, _scrollController.position.maxScrollExtent);
        if ((_scrollController.offset - targetOffset).abs() > 10) {
          _scrollController.jumpTo(targetOffset);
        }
      }
      _requestRowFocusFromMemory(rowIndex);
      _initialFocusResolved = true;
    });
  }

  String _hubKeyForRow(HomeRow row) => 'home_${row.id}';

  Future<void> _focusAdjacentRowItem(
    List<HomeRow> rows,
    int fromRowIndex,
    int direction,
  ) async {
    if (_verticalNavInFlight) return;
    _verticalNavInFlight = true;
    final maxRow = rows.length - 1;
    var target = fromRowIndex + direction;
    final fromState = _rowStateOf(fromRowIndex);
    final anchorGlobalX = fromState?.focusedItemGlobalCenterX();
    try {
      while (target >= 0 && target <= maxRow) {
        final candidate = rows[target];
        final hasItems = _rowHasFocusableItems(candidate);
        if (hasItems) {
          final targetState = _rowStateOf(target);
          if (targetState != null) {
            if (anchorGlobalX != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                targetState.requestFocusNearestToGlobalX(anchorGlobalX);
              });
            } else {
              _requestRowFocusFromMemory(target);
            }
          } else {
            _requestRowFocusFromMemory(target);
          }

          final navComplete = Completer<void>();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              if (!navComplete.isCompleted) navComplete.complete();
              return;
            }
            final rowCtx = _rowKeys[target]?.currentContext;
            if (rowCtx == null) {
              if (!navComplete.isCompleted) navComplete.complete();
              return;
            }

            final viewportHeight = _scrollController.hasClients
                ? _scrollController.position.viewportDimension
                : 768.0;
            final overlayEnabled =
                widget.prefs.get(UserPreferences.homeRowInfoOverlay);

            if (PlatformDetection.isTV &&
                overlayEnabled &&
                _scrollController.hasClients) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || !_scrollController.hasClients) {
                  if (!navComplete.isCompleted) navComplete.complete();
                  return;
                }
                final innerCtx = _rowKeys[target]?.currentContext;
                if (innerCtx == null) {
                  if (!navComplete.isCompleted) navComplete.complete();
                  return;
                }
                final renderObj = innerCtx.findRenderObject();
                if (renderObj is! RenderBox || !renderObj.hasSize) {
                  if (!navComplete.isCompleted) navComplete.complete();
                  return;
                }
                _scrollTvRowIntoOverlayBand(target).whenComplete(() {
                  if (!navComplete.isCompleted) navComplete.complete();
                });
              });
              return;
            }

            final alignment = overlayEnabled
                ? ((_overlayBottom + 120) / viewportHeight).clamp(0.05, 0.85)
                : 0.12;

            Scrollable.ensureVisible(
              rowCtx,
              alignment: alignment,
              duration: _focusHandoffDuration,
              curve: _focusHandoffCurve,
            ).whenComplete(() {
              if (!navComplete.isCompleted) navComplete.complete();
            });
          });
          await navComplete.future.timeout(
            const Duration(milliseconds: 450),
            onTimeout: () {},
          );
          return;
        }
        target += direction;
      }

      if (direction < 0) {
        if (_isMediaBarIncluded()) {
          _verticalNavInFlight = false;
          await _moveFocusFromRowsToMediaBar();
        } else {
          _navigateFromMediaBarToNavbar();
        }
      }
    } finally {
      _verticalNavInFlight = false;
    }
  }

  bool _allowVerticalNavNow() {
    final now = DateTime.now();
    if (_lastVerticalNavAt != null &&
        now.difference(_lastVerticalNavAt!) < const Duration(milliseconds: 140)) {
      return false;
    }
    _lastVerticalNavAt = now;
    return true;
  }

  bool _onRowVerticalNavigation({
    required int rowIndex,
    required List<HomeRow> rows,
    required bool isUp,
  }) {
    _markUserGesture();
    if (!_allowVerticalNavNow()) return true;
    if (isUp) {
      if (rowIndex == 0) {
        if (_isMediaBarIncluded()) {
          unawaited(_moveFocusFromRowsToMediaBar());
        } else {
          _navigateFromMediaBarToNavbar();
        }
      } else {
        unawaited(_focusAdjacentRowItem(rows, rowIndex, -1));
      }
    } else {
      unawaited(_focusAdjacentRowItem(rows, rowIndex, 1));
    }
    return true;
  }

  void _onRowLeftEdge() {
    final navbarIsLeft =
        widget.prefs.get(UserPreferences.navbarPosition) == NavbarPosition.left;
    if (!navbarIsLeft) return;
    final focusNavbar = NavigationLayout.focusNavbarNotifier.value;
    if (focusNavbar != null) focusNavbar();
  }

  void _onRowFocusTracked(int rowIndex, bool focused) {
    if (!mounted) return;
    if (focused) {
      if (_activeFocusedRowIndex != rowIndex && _activePreviewKey != null) {
        _finishSharedPreview();
      }
      _activeFocusedRowIndex = rowIndex;
      if (_mediaBarVisible) {
        setState(() => _mediaBarVisible = false);
      }
    } else if (_activeFocusedRowIndex == rowIndex) {
      if (_activePreviewKey != null) {
        _finishSharedPreview();
      }
      _activeFocusedRowIndex = null;
    }
  }

  KeyEventResult _handleRowsKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (!event.logicalKey.isUpKey) return KeyEventResult.ignored;

    final current = FocusManager.instance.primaryFocus;
    if (current == null) return KeyEventResult.ignored;

    if (_isMediaBarIncluded()) {
      if (current == _mediaBarFocusNode) return KeyEventResult.ignored;
      unawaited(_moveFocusFromRowsToMediaBar());
      return KeyEventResult.handled;
    }

    if (_activeFocusedRowIndex == 0) {
      _navigateFromMediaBarToNavbar();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _onScroll() {
    _lastScrollTime = DateTime.now();
    final offset = _scrollController.offset;
    final previousOffset = _scrollOffset;
    final scrollingUp = offset < previousOffset;
    final atTop = offset <= 0;
    if (atTop != _isScrolledToTop) {
      _isScrolledToTop = atTop;
      widget.onScrolledToTopChanged?.call(atTop);
    }

    if (!_isActivelyScrolling) {
      _isActivelyScrolling = true;
      if (mounted) setState(() {});
    }
    _scrollIdleTimer?.cancel();
    _scrollIdleTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _isActivelyScrolling = false;
      setState(() {});
    });
    if (_activePreviewKey != null) {
      final scrollDelta = (offset - _previewStartScrollOffset).abs();
      if (scrollDelta > _previewScrollThreshold) {
        _finishSharedPreview();
        return;
      }
    }

    if (_infoRevealed &&
        _isMediaBarIncluded() &&
        widget.prefs.get(UserPreferences.homeRowInfoOverlay)) {
      final collapseOffset = _pinnedInfoCollapseOffset();
      if (scrollingUp && offset < collapseOffset) {
        setState(() {
          _infoRevealed = false;
          _scrollOffset = offset;
        });
        return;
      }
    }

    if (_infoRevealed && _isMediaBarIncluded()) {
      setState(() => _scrollOffset = offset);
    } else {
      _scrollOffset = offset;
    }
  }

  double _libraryRowExtent(double rowHeight) => rowHeight + 34;

  double _estimatedRowExtent(
    HomeRow row,
    PosterSize posterSize,
    UserPreferences prefs,
  ) {
    if (row.isLoading) {
      return _libraryRowExtent(220);
    }

    if (row.rowType == HomeRowType.liveTv ||
        row.rowType == HomeRowType.libraryTilesSmall) {
      return _libraryRowExtent(140);
    }

    final rowImageType = _homeRowImageTypeForRow(row, prefs);
    final tvScale = PlatformDetection.isTV ? 0.8 : 1.0;
    var maxCardHeight = 220.0;
    for (final item in row.items) {
      final aspectRatio = _aspectRatioForRowItem(item, row, rowImageType);
      final imageHeight = (aspectRatio > 1
          ? posterSize.landscapeHeight.toDouble()
          : posterSize.portraitHeight.toDouble()) * tvScale;
      final cardHeight = imageHeight + 46;
      if (cardHeight > maxCardHeight) {
        maxCardHeight = cardHeight;
      }
    }

    return _libraryRowExtent(maxCardHeight);
  }

  double _overlayRowShift({
    required double rowViewportTop,
    required double rowExtent,
    required double overlayBottom,
  }) {
    if (rowViewportTop >= overlayBottom + 20) return 0;
    const transitionRange = 40.0;
    final progress =
        ((overlayBottom + 20 - rowViewportTop) / transitionRange).clamp(0.0, 1.0);
    final fullShift = (rowViewportTop + rowExtent + 10).clamp(0.0, double.infinity);
    return Curves.easeIn.transform(progress) * fullShift * 1.5;
  }

  Widget _buildShiftedRow({
    required Widget child,
    required int rowIndex,
    required List<double> rowTopOffsets,
    required List<double> rowExtents,
    required bool showInfoOverlay,
    required double overlayBottom,
  }) {
    if (!showInfoOverlay || !_infoRevealed) {
      return child;
    }

    if (!PlatformDetection.isTV && !_isMediaBarIncluded()) {
      return child;
    }

    if (PlatformDetection.isTV) {
      final focusedRowIndex = _focusedRowIndex(FocusManager.instance.primaryFocus);
      final rowViewportTop = rowTopOffsets[rowIndex] - _scrollOffset;
      final rowBottom = rowViewportTop + rowExtents[rowIndex];
      if (focusedRowIndex != null && rowIndex < focusedRowIndex) {
        return IgnorePointer(
          child: Opacity(opacity: 0, child: child),
        );
      }
      if (rowBottom < overlayBottom - 80) {
        return IgnorePointer(
          child: Opacity(opacity: 0, child: child),
        );
      }
      return child;
    }

    final focusedRowIndex = _focusedRowIndex(FocusManager.instance.primaryFocus);
    if (focusedRowIndex != null && rowIndex >= focusedRowIndex) {
      return child;
    }

    final rowViewportTop = rowTopOffsets[rowIndex] - _scrollOffset;
    final rowViewportBottom = rowViewportTop + rowExtents[rowIndex];

    if (rowViewportBottom <= overlayBottom + 8) {
      return IgnorePointer(
        child: Opacity(opacity: 0, child: child),
      );
    }

    if (focusedRowIndex != null &&
        focusedRowIndex < rowTopOffsets.length &&
        (rowTopOffsets[focusedRowIndex] - _scrollOffset) >= overlayBottom + 20) {
      return child;
    }

    final shift = _overlayRowShift(
      rowViewportTop: rowViewportTop,
      rowExtent: rowExtents[rowIndex],
      overlayBottom: overlayBottom,
    );
    if (shift <= 0) {
      return child;
    }

    const transitionRange = 40.0;
    final progress =
        ((overlayBottom + 20 - rowViewportTop) / transitionRange).clamp(0.0, 1.0);
    final opacity = (1.0 - (progress * 1.4)).clamp(0.0, 1.0);

    return ClipRect(
      child: Transform.translate(
        offset: Offset(0, -shift),
        child: Opacity(
          opacity: opacity,
          child: child,
        ),
      ),
    );
  }

  String _localizedRowTitle(HomeRow row, AppLocalizations l10n) {
    switch (row.id) {
      case 'resume':
        final merge = widget.prefs.get(UserPreferences.mergeContinueWatchingNextUp);
        return merge ? l10n.continueWatchingAndNextUp : l10n.continueWatching;
      case 'resumeAudio':
        return l10n.continueListening;
      case 'nextUp':
        return l10n.nextUp;
      case 'latestMedia':
        return l10n.latestMedia;
      case 'playlists':
        return l10n.playlists;
      case 'libraryTiles':
      case 'libraryTilesSmall':
        return l10n.myMedia;
      case 'liveTv':
        return l10n.liveTv;
      case 'activeRecordings':
        return l10n.activeRecordings;
      default:
        return row.title;
    }
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

    final includeMediaBar = _isMediaBarIncluded();
    final mediaBarHeight = _mediaBarHeight();
    final carouselPaused =
      widget.isHoverPaused ||
      !_isScrolledToTop ||
      _isActivelyScrolling ||
      _chromeFocusActive;
    final showInfoOverlay = prefs.get(UserPreferences.homeRowInfoOverlay);
    final safeTop = MediaQuery.of(context).padding.top;
    final listTopPadding = includeMediaBar || showInfoOverlay ? 0.0 : safeTop + 56;
    final navbarIsTop = widget.prefs.get(UserPreferences.navbarPosition) == NavbarPosition.top;
    final navbarIsLeft = !navbarIsTop;
    final navbarHeight = navbarIsTop && !(PlatformDetection.isTV && includeMediaBar)
        ? (PlatformDetection.isTV
            ? 95.0
            : PlatformDetection.useMobileUi
                ? 60.0
                : 80.0)
        : 0.0;
    final navbarLeftInset = navbarIsTop ? 16.0 : 56.0;
    final rowLeftInset = (navbarIsLeft && PlatformDetection.isTV) ? 56.0 : 0.0;
    final infoTopPadding = safeTop + navbarHeight + 8;
    final infoAreaHeight = InfoArea.fixedHeight(isMobile: PlatformDetection.useMobileUi);
    final infoBottomPadding = includeMediaBar ? 20.0 : 8.0;
    // Reserve the info band height up-front so revealing/hiding the InfoArea
    // overlay (a Stack child) does not shift row positions in the ListView.
    final infoPlaceholderHeight = showInfoOverlay
        ? infoTopPadding + infoAreaHeight + infoBottomPadding
        : 0.0;
    final overlayBottom = infoTopPadding + infoAreaHeight;
    final rowExtents = rows
        .map((row) => _estimatedRowExtent(row, posterSize, prefs))
        .toList(growable: false);
    final rowTopOffsets = <double>[];
    var currentTop = listTopPadding + infoPlaceholderHeight;
    if (includeMediaBar) {
      currentTop += mediaBarHeight;
    }
    for (final rowExtent in rowExtents) {
      rowTopOffsets.add(currentTop);
      currentTop += rowExtent;
    }

    _rowTopOffsets = rowTopOffsets;
    _overlayBottom = overlayBottom;
    final headerCount = (includeMediaBar ? 1 : 0) + 1;

    // Ensure the last row can be scrolled so its top sits just below the info
    // overlay; otherwise scroll targets clamp to maxScrollExtent and rows drift
    // higher in the viewport as the user navigates downward.
    final viewportHeight = MediaQuery.of(context).size.height;
    final lastRowExtent = rowExtents.isEmpty ? 0.0 : rowExtents.last;
    final neededBottomPadding =
        (viewportHeight - (overlayBottom + 8) - lastRowExtent)
            .clamp(32.0, double.infinity);

    _ensureInitialHomeFocus(rows);

    if (!widget.viewModel.isLoading && rows.isEmpty && !includeMediaBar) {
      final l10n = AppLocalizations.of(context);
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.noHomeRowsLoaded,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noHomeRowsHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => widget.viewModel.refresh(preserveExisting: false),
              child: Text(l10n.retryHomeRows),
            ),
          ],
        ),
      );
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _markUserGesture(),
      child: Stack(
        children: [
        Positioned.fill(
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: (_, event) => _handleRowsKeyEvent(event),
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.only(
                top: listTopPadding,
                bottom: neededBottomPadding,
              ),
              itemCount: rows.length + headerCount,
              cacheExtent: 600,
              itemBuilder: (context, index) {
              if (includeMediaBar && index == 0) {
                return AnimatedOpacity(
                  duration: _mediaBarFadeDuration,
                  curve: Curves.easeInOutCubic,
                  opacity: _mediaBarVisible ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !_mediaBarVisible,
                    child: MediaBar(
                      viewModel: widget.mediaBarViewModel,
                      prefs: prefs,
                      externallyPaused: carouselPaused || !_mediaBarVisible,
                      height: mediaBarHeight,
                      onNavigateDown: _moveFocusFromMediaBarToRows,
                      onNavigateUp: _navigateFromMediaBarToNavbar,
                      onNavigateLeft: navbarIsLeft ? _navigateFromMediaBarToNavbar : null,
                      focusNode: _mediaBarFocusNode,
                    ),
                  ),
                );
              }
              final infoIndex = includeMediaBar ? 1 : 0;
              if (index == infoIndex) {
                return SizedBox(height: infoPlaceholderHeight);
              }
              final row = rows[index - headerCount];
              final rowIndex = index - headerCount;
              final l10n = AppLocalizations.of(context);
              late final Widget rowChild;
              if (row.isLoading) {
                rowChild = LibraryRow(
                  title: _localizedRowTitle(row, l10n),
                  children: const [],
                );
                return Padding(
                  padding: EdgeInsets.only(left: rowLeftInset),
                  child: _buildShiftedRow(
                    child: rowChild,
                    rowIndex: rowIndex,
                    rowTopOffsets: rowTopOffsets,
                    rowExtents: rowExtents,
                    showInfoOverlay: showInfoOverlay,
                    overlayBottom: overlayBottom,
                  ),
                );
              } else if (row.rowType == HomeRowType.liveTv) {
                rowChild = _buildLiveTvRow(
                  row,
                  focusColor,
                  cardExpansion,
                  rowIndex: rowIndex,
                  rows: rows,
                );
              } else if (row.rowType == HomeRowType.libraryTilesSmall) {
                rowChild = _buildLibraryButtonsRow(
                  row,
                  focusColor,
                  cardExpansion,
                  rowIndex: rowIndex,
                  rows: rows,
                );
              } else {
                rowChild = _buildMediaRow(
                  row: row,
                  rowIndex: rowIndex,
                  rows: rows,
                  prefs: prefs,
                  posterSize: posterSize,
                  watchedBehavior: watchedBehavior,
                  focusColor: focusColor,
                  cardExpansion: cardExpansion,
                  useSeriesThumbs: useSeriesThumbs,
                  l10n: l10n,
                );
              }
              return Padding(
                padding: EdgeInsets.only(left: rowLeftInset),
                child: _buildShiftedRow(
                  child: rowChild,
                  rowIndex: rowIndex,
                  rowTopOffsets: rowTopOffsets,
                  rowExtents: rowExtents,
                  showInfoOverlay: showInfoOverlay,
                  overlayBottom: overlayBottom,
                ),
              );
              },
            ),
          ),
        ),
          if (_infoRevealed && showInfoOverlay)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    navbarLeftInset,
                    infoTopPadding,
                    16,
                    8,
                  ),
                  child: InfoArea(item: widget.selectedItem),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveTvRow(
    HomeRow row,
    Color focusColor,
    bool cardExpansion, {
    required int rowIndex,
    required List<HomeRow> rows,
  }) {
    final l10n = AppLocalizations.of(context);
    final actions = <_LiveTvAction>[
      _LiveTvAction(Icons.tv_rounded, l10n.guide, Destinations.liveTvGuide),
      _LiveTvAction(Icons.fiber_manual_record_rounded, l10n.recordings,
          Destinations.liveTvRecordings),
      _LiveTvAction(Icons.schedule_rounded, l10n.schedule,
          Destinations.liveTvSchedule),
      _LiveTvAction(Icons.movie_creation, l10n.series,
          Destinations.liveTvSeriesRecordings),
    ];
    return _buildTitledRow(
      key: _rowContainerKey(rowIndex),
      title: _localizedRowTitle(row, l10n),
      height: 140,
      child: LockedFocusRow<_LiveTvAction>(
        key: _rowKey(rowIndex),
        items: actions,
        hubKey: _hubKeyForRow(row),
        height: 140,
        itemExtent: 160,
        itemSpacing: 12,
        leadingPadding: 0,
        padding: const EdgeInsets.fromLTRB(16, 5, 20, 5),
        onIndexChanged: (_, __) {
          _onHomeRowTileFocused(null);
        },
        onFocusChange: (has) => _onRowFocusTracked(rowIndex, has),
        onVerticalNavigation: (isUp) => _onRowVerticalNavigation(
          rowIndex: rowIndex,
          rows: rows,
          isUp: isUp,
        ),
        onLeftEdge: _onRowLeftEdge,
        onTap: (_, action) => context.push(action.destination),
        itemBuilder: (ctx, action, idx, isFocused) {
          return GridButtonCard(
            icon: action.icon,
            label: action.label,
            focusColor: focusColor,
            cardFocusExpansion: cardExpansion,
            externalIsFocused: isFocused,
            onTap: () => context.push(action.destination),
          );
        },
      ),
    );
  }

  Widget _buildLibraryButtonsRow(
    HomeRow row,
    Color focusColor,
    bool cardExpansion, {
    required int rowIndex,
    required List<HomeRow> rows,
  }) {
    final l10n = AppLocalizations.of(context);
    return _buildTitledRow(
      key: _rowContainerKey(rowIndex),
      title: _localizedRowTitle(row, l10n),
      height: 140,
      child: LockedFocusRow<AggregatedItem>(
        key: _rowKey(rowIndex),
        items: row.items,
        hubKey: _hubKeyForRow(row),
        height: 140,
        itemExtent: 160,
        itemSpacing: 12,
        leadingPadding: 0,
        padding: const EdgeInsets.fromLTRB(16, 5, 20, 5),
        onIndexChanged: (_, item) {
          _onHomeRowTileFocused(item);
        },
        onFocusChange: (has) => _onRowFocusTracked(rowIndex, has),
        onVerticalNavigation: (isUp) => _onRowVerticalNavigation(
          rowIndex: rowIndex,
          rows: rows,
          isUp: isUp,
        ),
        onLeftEdge: _onRowLeftEdge,
        onTap: (_, item) => _navigateToLibrary(context, item),
        itemBuilder: (ctx, item, idx, isFocused) {
          final collectionType =
              (item.rawData['CollectionType'] as String? ?? '').toLowerCase();
          final icon = _iconForCollectionType(collectionType);
          return GridButtonCard(
            icon: icon,
            label: item.name,
            focusColor: focusColor,
            cardFocusExpansion: cardExpansion,
            externalIsFocused: isFocused,
            onTap: () => _navigateToLibrary(context, item),
          );
        },
      ),
    );
  }

  Widget _buildMediaRow({
    required HomeRow row,
    required int rowIndex,
    required List<HomeRow> rows,
    required UserPreferences prefs,
    required PosterSize posterSize,
    required WatchedIndicatorBehavior watchedBehavior,
    required Color focusColor,
    required bool cardExpansion,
    required bool useSeriesThumbs,
    required AppLocalizations l10n,
  }) {
    final rowImageType = _homeRowImageTypeForRow(row, prefs);
    final tvScale = PlatformDetection.isTV ? 0.8 : 1.0;

    double maxCardHeight = 0;
    double firstCardWidth = 0;
    for (final item in row.items) {
      final ar = _aspectRatioForRowItem(item, row, rowImageType);
      final height = (ar > 1
              ? posterSize.landscapeHeight.toDouble()
              : posterSize.portraitHeight.toDouble()) *
          tvScale;
      final cardHeight = height + 46;
      if (cardHeight > maxCardHeight) maxCardHeight = cardHeight;
      if (firstCardWidth == 0) firstCardWidth = height * ar;
    }

    return _buildTitledRow(
      key: _rowContainerKey(rowIndex),
      title: _localizedRowTitle(row, l10n),
      height: maxCardHeight + 10,
      child: LockedFocusRow<AggregatedItem>(
        key: _rowKey(rowIndex),
        items: row.items,
        hubKey: _hubKeyForRow(row),
        height: maxCardHeight + 10,
        itemExtent: firstCardWidth,
        itemSpacing: 12,
        leadingPadding: 0,
        padding: const EdgeInsets.fromLTRB(16, 5, 20, 5),
        onFocusChange: (has) => _onRowFocusTracked(rowIndex, has),
        onVerticalNavigation: (isUp) => _onRowVerticalNavigation(
          rowIndex: rowIndex,
          rows: rows,
          isUp: isUp,
        ),
        onLeftEdge: _onRowLeftEdge,
        onIndexChanged: (_, item) {
          final forceReveal = _forceRevealOnNextRowFocusFromMediaBar;
          _forceRevealOnNextRowFocusFromMediaBar = false;
          widget.onItemSelected(item);
          unawaited(_revealAndScrollToPinnedInfo(ignoreScrollCooldown: forceReveal));
          if (_suppressNextRowPreviewFromMediaBar) {
            _suppressNextRowPreviewFromMediaBar = false;
            _finishSharedPreview();
            return;
          }
          final canPreview = _supportsEpisodePreview(item);
          if (!PlatformDetection.useMobileUi && canPreview) {
            _schedulePreview(item, delay: _previewStartDelay);
          } else {
            _finishSharedPreview();
          }
        },
        onTap: (_, item) {
          _finishSharedPreview(releaseResources: true);
          if (row.rowType == HomeRowType.libraryTiles) {
            _navigateToLibrary(context, item);
          } else {
            context.push(Destinations.itemOrPhoto(
              item.id,
              serverId: item.serverId,
              type: item.type,
            ));
          }
        },
        itemBuilder: (ctx, item, idx, isFocused) {
          final ar = _aspectRatioForRowItem(item, row, rowImageType);
          final height = (ar > 1
                  ? posterSize.landscapeHeight.toDouble()
                  : posterSize.portraitHeight.toDouble()) *
              tvScale;
          final width = height * ar;
          final imageUrl = _resolveRowImageUrl(
            item,
            widget.viewModel.imageApiForServer(item.serverId),
            height,
            rowImageType,
            useSeriesThumbs,
            isMyMediaRow: row.rowType == HomeRowType.libraryTiles,
          );
          final previewKey = _previewKeyFor(item);
          final canPreview = _supportsEpisodePreview(item);

          final showPreviewVideo =
              _activePreviewKey == previewKey && _previewReady;

          final card = MediaCard(
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
            cardFocusExpansion: cardExpansion && !showPreviewVideo,
            externalIsFocused: isFocused,
            suppressImageFocusBorder: showPreviewVideo,
            onHoverStart: () {
              unawaited(_revealAndScrollToPinnedInfo());
              widget.onItemSelected(item);
              if (!PlatformDetection.useMobileUi && canPreview) {
                _schedulePreview(item, delay: _previewStartDelay);
              } else {
                _finishSharedPreview();
              }
            },
            onHoverEnd: () {
              _stopPreviewFor(item);
            },
            onLongPress: () => showContextMenu(
              context,
              item,
              onChanged: () => setState(() {}),
            ),
            onTap: () {
              _finishSharedPreview(releaseResources: true);
              if (row.rowType == HomeRowType.libraryTiles) {
                _navigateToLibrary(context, item);
              } else {
                context.push(Destinations.itemOrPhoto(
                  item.id,
                  serverId: item.serverId,
                  type: item.type,
                ));
              }
            },
          );

          if (!canPreview) return card;
          return _PreviewCardShell(
            card: card,
            width: width,
            aspectRatio: ar,
            showVideo: showPreviewVideo,
            controller: _previewController,
            isFocused: isFocused,
            focusColor: focusColor,
          );
        },
      ),
    );
  }

  Widget _buildTitledRow({
    Key? key,
    required String title,
    required double height,
    required Widget child,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        child,
      ],
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
        context.push(Destinations.library(item.id, bookUi: true));
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

  static ImageType _homeRowImageTypeForRow(HomeRow row, UserPreferences prefs) {
    if (row.rowType == HomeRowType.latestMedia && _isLatestMusicRow(row)) {
      return ImageType.poster;
    }

    if (prefs.get(UserPreferences.homeRowsUniversalOverride)) {
      return prefs.get(UserPreferences.homeRowsUniversalImageType);
    }

    final sectionType = _sectionTypeForRow(row);
    if (sectionType == null) {
      return ImageType.poster;
    }
    return prefs.get(UserPreferences.homeRowImageType(sectionType));
  }

  static HomeSectionType? _sectionTypeForRow(HomeRow row) {
    return switch (row.rowType) {
      HomeRowType.resume => HomeSectionType.resume,
      HomeRowType.nextUp => HomeSectionType.nextUp,
      HomeRowType.latestMedia => HomeSectionType.latestMedia,
      HomeRowType.libraryTiles => HomeSectionType.libraryTilesSmall,
      HomeRowType.playlists => HomeSectionType.playlists,
      HomeRowType.liveTv => HomeSectionType.liveTv,
      HomeRowType.activeRecordings => HomeSectionType.activeRecordings,
      _ => null,
    };
  }

  static bool _isLatestMusicRow(HomeRow row) {
    if (row.rowType != HomeRowType.latestMedia || row.items.isEmpty) return false;
    return row.items.every((item) =>
        item.type == 'Audio' || item.type == 'MusicAlbum' || item.type == 'MusicArtist');
  }

  static double _aspectRatioForRowItem(
    AggregatedItem item,
    HomeRow row,
    ImageType imageType,
  ) {
    double thumbAspectRatio() {
      return switch (item.type) {
        'MusicAlbum' || 'MusicArtist' || 'Audio' || 'Playlist' || 'Person' => 1,
        _ => 16 / 9,
      };
    }

    return switch (imageType) {
      ImageType.thumb || ImageType.banner => thumbAspectRatio(),
      ImageType.poster => MediaCard.aspectRatioForType(item.type),
    };
  }

  static String? _resolveRowImageUrl(
    AggregatedItem item,
    ImageApi imageApi,
    double height,
    ImageType imageType,
    bool useSeriesThumbs,
    {bool isMyMediaRow = false}
  ) {
    final itemThumbTag = _tagForType(item, 'Thumb');
    final itemBannerTag = _tagForType(item, 'Banner');
    final parentThumbItemId = item.rawData['ParentThumbItemId'] as String?;
    final parentThumbTag = item.rawData['ParentThumbImageTag'] as String?;

    if (useSeriesThumbs && item.type == 'Episode') {
      final seriesImage = _resolveSeriesImageForRowType(
        item,
        imageApi,
        height,
        imageType,
      );
      if (seriesImage != null) {
        return seriesImage;
      }
    }

    if (imageType == ImageType.banner) {
      final maxW = (height * 16 / 9 * 2).toInt();
      if (isMyMediaRow && item.primaryImageTag != null) {
        return imageApi.getPrimaryImageUrl(item.id, maxWidth: maxW, tag: item.primaryImageTag);
      }
      if (itemBannerTag != null) {
        return imageApi.getBannerImageUrl(item.id, maxWidth: maxW, tag: itemBannerTag);
      }
      if (itemThumbTag != null) {
        return imageApi.getThumbImageUrl(item.id, maxWidth: maxW, tag: itemThumbTag);
      }
      if (item.backdropImageTags.isNotEmpty) {
        return imageApi.getBackdropImageUrl(item.id, maxWidth: maxW, tag: item.backdropImageTags.first);
      }
      return _resolveImageUrl(item, imageApi, height, useSeriesThumbs);
    }

    if (imageType == ImageType.thumb) {
      final maxW = (height * 16 / 9 * 2).toInt();
      if (itemThumbTag != null) {
        return imageApi.getThumbImageUrl(item.id, maxWidth: maxW, tag: itemThumbTag);
      }
      if (item.backdropImageTags.isNotEmpty) {
        return imageApi.getBackdropImageUrl(item.id, maxWidth: maxW, tag: item.backdropImageTags.first);
      }
      if (parentThumbItemId != null && parentThumbTag != null) {
        return imageApi.getThumbImageUrl(parentThumbItemId, maxWidth: maxW, tag: parentThumbTag);
      }
      if (item.parentBackdropItemId != null && item.parentBackdropImageTags.isNotEmpty) {
        return imageApi.getBackdropImageUrl(
          item.parentBackdropItemId!,
          maxWidth: maxW,
          tag: item.parentBackdropImageTags.first,
        );
      }
      return _resolveLandscapeImageUrl(item, imageApi, height);
    }

    return _resolveImageUrl(item, imageApi, height, useSeriesThumbs);
  }

  static String? _resolveSeriesImageForRowType(
    AggregatedItem item,
    ImageApi imageApi,
    double height,
    ImageType imageType,
  ) {
    final maxW = (height * 16 / 9 * 2).toInt();
    final maxH = (height * 2).toInt();
    final seriesId = item.seriesId;
    final seriesPrimaryTag = item.seriesPrimaryImageTag;
    final parentThumbItemId = item.rawData['ParentThumbItemId'] as String?;
    final parentThumbTag = item.rawData['ParentThumbImageTag'] as String?;
    final parentBackdropItemId = item.parentBackdropItemId;
    final parentBackdropTags = item.parentBackdropImageTags;

    if (imageType == ImageType.poster) {
      if (seriesId != null && seriesPrimaryTag != null) {
        return imageApi.getPrimaryImageUrl(
          seriesId,
          maxHeight: maxH,
          tag: seriesPrimaryTag,
        );
      }
      return null;
    }

    if (imageType == ImageType.thumb) {
      if (parentThumbItemId != null && parentThumbTag != null) {
        return imageApi.getThumbImageUrl(
          parentThumbItemId,
          maxWidth: maxW,
          tag: parentThumbTag,
        );
      }
      if (parentBackdropItemId != null && parentBackdropTags.isNotEmpty) {
        return imageApi.getBackdropImageUrl(
          parentBackdropItemId,
          maxWidth: maxW,
          tag: parentBackdropTags.first,
        );
      }
      if (seriesId != null && seriesPrimaryTag != null) {
        return imageApi.getPrimaryImageUrl(
          seriesId,
          maxWidth: maxW,
          tag: seriesPrimaryTag,
        );
      }
      return null;
    }

    if (imageType == ImageType.banner) {
      final seriesBannerTag = (item.rawData['SeriesImageTags'] as Map?)?['Banner'] as String?;
      if (seriesId != null && seriesBannerTag != null) {
        return imageApi.getBannerImageUrl(
          seriesId,
          maxWidth: maxW,
          tag: seriesBannerTag,
        );
      }
      if (parentThumbItemId != null && parentThumbTag != null) {
        return imageApi.getThumbImageUrl(
          parentThumbItemId,
          maxWidth: maxW,
          tag: parentThumbTag,
        );
      }
      if (parentBackdropItemId != null && parentBackdropTags.isNotEmpty) {
        return imageApi.getBackdropImageUrl(
          parentBackdropItemId,
          maxWidth: maxW,
          tag: parentBackdropTags.first,
        );
      }
      if (seriesId != null && seriesPrimaryTag != null) {
        return imageApi.getPrimaryImageUrl(
          seriesId,
          maxWidth: maxW,
          tag: seriesPrimaryTag,
        );
      }
      return null;
    }

    return null;
  }

  static String? _tagForType(AggregatedItem item, String imageType) {
    final tags = item.rawData['ImageTags'];
    if (tags is! Map) return null;
    return tags[imageType] as String?;
  }
}

class _LiveTvAction {
  final IconData icon;
  final String label;
  final String destination;

  const _LiveTvAction(this.icon, this.label, this.destination);
}

class _PreviewCardShell extends StatelessWidget {
  final Widget card;
  final double width;
  final double aspectRatio;
  final bool showVideo;
  final VideoController? controller;
  final bool isFocused;
  final Color focusColor;

  const _PreviewCardShell({
    required this.card,
    required this.width,
    required this.aspectRatio,
    required this.showVideo,
    required this.controller,
    required this.isFocused,
    required this.focusColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!showVideo || controller == null) {
      return card;
    }

    return SizedBox(
      width: width,
      child: Stack(
        children: [
          card,
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SizedBox(
              height: width / aspectRatio,
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ColoredBox(
                    color: Colors.black,
                    child: Video(
                      controller: controller!,
                      controls: NoVideoControls,
                      fit: BoxFit.cover,
                      pauseUponEnteringBackgroundMode: false,
                      fill: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isFocused)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: IgnorePointer(
                child: Container(
                  height: width / aspectRatio,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: focusColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


