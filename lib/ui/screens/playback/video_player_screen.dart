import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_design/jellyfin_design.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:playback_core/playback_core.dart';
import 'package:server_core/server_core.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';
import 'package:window_manager/window_manager.dart';

import '../../../playback/media_kit_player_backend.dart';
import '../../../data/models/aggregated_item.dart';
import '../../../data/models/media_segment.dart';
import '../../../data/models/trickplay_info.dart';
import '../../../data/services/cast/cast_service.dart';
import '../../../data/services/cast/cast_target.dart';
import '../../../data/services/cast/native_airplay_channel.dart';
import '../../../data/services/cast/native_cast_channel.dart';
import '../../../data/services/cast/native_dlna_channel.dart';
import '../../../data/services/media_segment_service.dart';
import '../../../data/services/media_server_client_factory.dart';
import '../../../platform/pip_service.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/audio_labels.dart';
import '../../../util/platform_detection.dart';
import '../../widgets/remote_play_to_session_dialog.dart';
import '../../widgets/playback/skip_segment_overlay.dart';
import '../../widgets/playback/next_up_overlay.dart';
import '../../widgets/playback/still_watching_dialog.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with WidgetsBindingObserver {
  static final _camelCaseSpaceRe = RegExp(r'(?<=[a-z])(?=[A-Z])');

  final _manager = GetIt.instance<PlaybackManager>();
  final _backend = GetIt.instance<MediaKitPlayerBackend>();
  final _prefs = GetIt.instance<UserPreferences>();
  final _clientFactory = GetIt.instance<MediaServerClientFactory>();
  final _castService = GetIt.instance<CastService>();
  final _nativeCast = GetIt.instance<NativeCastChannel>();
  final _nativeDlna = GetIt.instance<NativeDlnaChannel>();
  final _nativeAirPlay = GetIt.instance<NativeAirPlayChannel>();
  final _pipService = GetIt.instance<PipService>();
  late MediaSegmentService _segmentService;

  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _isSeeking = false;
  double _seekValue = 0;
  late ZoomMode _zoomMode;
  double _audioDelay = 0.0;
  double _subtitleDelay = 0.0;
  bool _isStopping = false;
  bool _isOsdLocked = false;
  String? _remotePlaybackState;
  int _remotePositionTicks = 0;
  double? _remoteVolume;
  DateTime? _lastCastErrorAt;
  String? _lastCastErrorMessage;
  bool _isInPiP = false;
  double _playerVolume = 100.0;
  bool _didRequestIosPiPForBackground = false;
  bool _isStartingIosPiPForBackground = false;
  Duration? _positionBeforeScreenLock;
  StreamSubscription? _screenLockSub;
  bool _isRestoringPosition = false;

  MediaSegment? _skipSegment;
  Duration? _skipTo;
  bool _showNextUp = false;
  AggregatedItem? _nextUpItem;
  bool _nextUpDismissed = false;
  bool _isNextUpAdvancing = false;
  int _consecutiveEpisodes = 0;
  StreamSubscription? _positionSub;
  StreamSubscription? _queueSub;
  StreamSubscription? _pipChangedSub;
  StreamSubscription? _pipActionSub;
  StreamSubscription? _playingSub;
  StreamSubscription? _bufferingSub;
  StreamSubscription<Map<String, dynamic>>? _castEventsSub;
  StreamSubscription<Map<String, dynamic>>? _dlnaEventsSub;
  StreamSubscription<Map<String, dynamic>>? _airPlayEventsSub;

  TrickplayInfo? _trickplayInfo;
  String? _trickplayMediaSourceId;

  final _overlayFocus = FocusNode();
  bool _isDesktopFullscreen = false;

  double _brightnessValue = 0.5;
  bool _showVolumeOverlay = false;
  bool _showBrightnessOverlay = false;
  Timer? _volumeOverlayTimer;
  Timer? _brightnessOverlayTimer;
  double _verticalDragStartY = 0.0;
  double _verticalDragStartValue = 0.0;
  bool _verticalDragIsVolume = false;
  Offset? _doubleTapDownPosition;
  bool _showSkipForward = false;
  bool _showSkipBackward = false;
  Timer? _skipForwardTimer;
  Timer? _skipBackwardTimer;
  int _skipForwardAccum = 0;
  int _skipBackwardAccum = 0;

  PlayerState get _state => _manager.state;
  QueueService get _queue => _manager.queueService;

  MediaServerClient _clientForItem(AggregatedItem item) {
    return _clientFactory.getClientIfExists(item.serverId) ??
        GetIt.instance<MediaServerClient>();
  }

  MediaSegmentService _createSegmentService([AggregatedItem? item]) {
    final client = item != null
        ? _clientForItem(item)
        : GetIt.instance<MediaServerClient>();
    return MediaSegmentService(
      client,
      FeatureDetector(serverType: client.serverType, serverVersion: ''),
      _prefs,
    );
  }

  @override
  void initState() {
    super.initState();
    _segmentService = _createSegmentService();
    _zoomMode = _prefs.get(UserPreferences.playerZoomMode);
    _applySubtitleStyle();
    _scheduleHide();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    WidgetsBinding.instance.addObserver(this);
    _loadSegmentsForCurrentItem();
    _positionSub = _state.positionStream.listen(_onPositionUpdate);
    if (PlatformDetection.isAndroid || PlatformDetection.isIOS) {
      _castEventsSub = _nativeCast.googleCastEventStream().listen(
        (e) => _onRemoteEvent(e, expectedKind: 'googleCast', castKind: CastTargetKind.googleCast),
        onError: (_) {},
      );
      _dlnaEventsSub = _nativeDlna.dlnaEventStream().listen(
        (e) => _onRemoteEvent(e, expectedKind: 'dlna', castKind: CastTargetKind.dlna),
        onError: (_) {},
      );
      if (PlatformDetection.isIOS) {
        _airPlayEventsSub = _nativeAirPlay.airPlayEventStream().listen(
          _onAirPlayEvent,
          onError: (_) {},
        );
      }
    }
    _queueSub = _queue.queueChangedStream.listen((_) {
      _loadSegmentsForCurrentItem();
      _manager.suppressAutoNext = false;
      _consecutiveEpisodes++;
      setState(() {
        _nextUpDismissed = false;
        _showNextUp = false;
        _skipSegment = null;
      });
    });

    if (PlatformDetection.isAndroid || PlatformDetection.isIOS) {
      _pipChangedSub = _pipService.onPiPChanged.listen(_onPiPChanged);
      _pipActionSub = _pipService.onPiPAction.listen(_onPiPAction);
      _playingSub = _state.playingStream.listen((playing) {
        _pipService.updatePiPActions(isPlaying: playing);
        _syncAirPlayPlaybackState();
      });
      if (PlatformDetection.isAndroid) {
        _pipService.enableAutoPiP(true);
        _bufferingSub = _state.bufferingStream.listen((_) {
          _syncAirPlayPlaybackState();
        });
      }
    }

    if (PlatformDetection.isAndroid) {
      _screenLockSub = _pipService.onScreenLock.listen(_onScreenLock);
    }

    if (PlatformDetection.isDesktop) {
      unawaited(_syncDesktopFullscreenState());
    }

    if (PlatformDetection.isMobile) {
      _initBrightness();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _volumeOverlayTimer?.cancel();
    _brightnessOverlayTimer?.cancel();
    _skipForwardTimer?.cancel();
    _skipBackwardTimer?.cancel();
    if (PlatformDetection.isMobile) {
      Future.microtask(() async {
        try {
          await ScreenBrightnessPlatform.instance
              .resetApplicationScreenBrightness();
        } catch (_) {}
      });
    }
    _positionSub?.cancel();
    _queueSub?.cancel();
    _pipChangedSub?.cancel();
    _pipActionSub?.cancel();
    _playingSub?.cancel();
    _bufferingSub?.cancel();
    _castEventsSub?.cancel();
    _dlnaEventsSub?.cancel();
    _airPlayEventsSub?.cancel();
    _screenLockSub?.cancel();
    _overlayFocus.dispose();
    _pipService.enableAutoPiP(false);
    if (!_isStopping) _manager.stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  void _onAirPlayEvent(Map<String, dynamic> event) {
    final kind = event['kind'] as String?;
    if (kind != 'airPlay') return;

    _onRemoteEvent(event, expectedKind: 'airPlay', castKind: CastTargetKind.airPlay);
  }

  void _onRemoteEvent(
    Map<String, dynamic> event, {
    required String expectedKind,
    required CastTargetKind castKind,
  }) {
    final kind = event['kind'] as String?;
    if (kind != expectedKind) return;

    final state = event['state'] as String?;
    switch (state) {
      case 'connected':
        _castService.setActiveKind(castKind);
        _castService.remoteStateNotifier.value = null;
        if (castKind == CastTargetKind.googleCast || castKind == CastTargetKind.dlna) {
          _refreshRemoteVolume();
        }
        if (castKind == CastTargetKind.airPlay) {
          _syncAirPlayPlaybackState();
        }
      case 'disconnected':
        if (_castService.activeKind == castKind) {
          _castService.setActiveKind(null);
          _castService.remoteStateNotifier.value = null;
          _castService.remotePositionNotifier.value = 0;
          _castService.remoteVolumeNotifier.value = null;
          _remotePlaybackState = null;
          _remotePositionTicks = 0;
          _remoteVolume = null;
        }
      case 'playing' || 'paused' || 'buffering' || 'idle':
        final positionTicks = (event['positionTicks'] as int?) ?? 0;
        _castService.remoteStateNotifier.value = state;
        _castService.remotePositionNotifier.value = positionTicks;
        if (mounted) {
          setState(() {
            _remotePlaybackState = state;
            _remotePositionTicks = positionTicks;
          });
        }
      case 'error':
        if (mounted) {
          final protocolLabel = castKind == CastTargetKind.googleCast ? 'Google Cast' : 'DLNA';
          final message = event['message'] as String? ?? '$protocolLabel session error';
          _showThrottledCastError(message);
        }
    }
  }

  void _showThrottledCastError(String message) {
    final now = DateTime.now();
    final lastAt = _lastCastErrorAt;
    final repeated = _lastCastErrorMessage == message;
    if (repeated && lastAt != null && now.difference(lastAt) < const Duration(seconds: 3)) {
      return;
    }
    _lastCastErrorAt = now;
    _lastCastErrorMessage = message;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refreshRemoteVolume() async {
    final kind = _castService.activeKind;
    if (kind == null || !mounted) return;

    try {
      final volume = await _castService.getVolume(kind);
      if (!mounted) return;
      _castService.remoteVolumeNotifier.value = volume;
      setState(() {
        _remoteVolume = volume;
      });
    } catch (_) {
      if (!mounted) return;
      _castService.remoteVolumeNotifier.value = null;
      setState(() {
        _remoteVolume = null;
      });
    }
  }

  Future<void> _setRemoteVolume(double volume) async {
    final kind = _castService.activeKind;
    if (kind == null || !mounted) return;
    _castService.remoteVolumeNotifier.value = volume;
    setState(() {
      _remoteVolume = volume;
    });
    try {
      await _castService.setVolume(kind, volume: volume);
    } catch (e) {
      if (!mounted) return;
      _showThrottledCastError('Failed to set cast volume: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    switch (lifecycleState) {
      case AppLifecycleState.inactive:
        if (PlatformDetection.isIOS) {
          _tryStartIosPiPForBackground();
          return;
        }
      case AppLifecycleState.hidden:
        if (PlatformDetection.isIOS) {
          _tryStartIosPiPForBackground();
          return;
        }
        if (_isInPiP || _isStopping || _pipService.isScreenLocked) return;
        _backend.setVideoEnabled(false);
      case AppLifecycleState.resumed:
        _didRequestIosPiPForBackground = false;
        if (PlatformDetection.isIOS && _isInPiP) {
          _pipService.enableAutoPiP(false);
        }
        _backend.setVideoEnabled(true);
        _restorePositionAfterScreenLock();
      default:
        break;
    }
  }

  void _tryStartIosPiPForBackground() {
    if (_didRequestIosPiPForBackground) return;
    if (_isStartingIosPiPForBackground) return;
    if (_isInPiP || _isStopping || _pipService.isScreenLocked) return;
    _didRequestIosPiPForBackground = true;
    _isStartingIosPiPForBackground = true;
    unawaited(_startIosPiPForBackground());
  }

  Future<void> _startIosPiPForBackground() async {
    try {
      await _pipService.startIosPiP();

      // Re-arm if PiP hasn't started after the method channel returned.
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (mounted && !_isInPiP) {
        _didRequestIosPiPForBackground = false;
      }
    } finally {
      _isStartingIosPiPForBackground = false;
    }
  }

  void _onScreenLock(bool locked) {
    if (locked) {
      _positionBeforeScreenLock = _backend.position;
      _isRestoringPosition = true;
    }
  }

  Future<void> _restorePositionAfterScreenLock() async {
    final pos = _positionBeforeScreenLock;
    if (pos == null || pos == Duration.zero) {
      if (_isRestoringPosition && mounted) {
        setState(() => _isRestoringPosition = false);
      }
      return;
    }
    _positionBeforeScreenLock = null;
    // The surface re-creation triggers a second decoder allocation up to ~700ms
    // after the activity resumes. Wait long enough for it to settle.
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _isStopping) return;
    await _backend.seekTo(pos);
    if (mounted) setState(() => _isRestoringPosition = false);
  }

  void _onPiPChanged(bool isInPiP) {
    if (!mounted) return;
    setState(() => _isInPiP = isInPiP);
    if (!isInPiP) {
      _didRequestIosPiPForBackground = false;
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  void _onPiPAction(String action) {
    switch (action) {
      case 'playPause':
        if (_state.isPlaying) {
          _manager.pause();
        } else {
          _manager.resume();
        }
      case 'play':
        _manager.resume();
      case 'pause':
        _manager.pause();
      case 'dismissed':
        _exitPlayback();
    }
  }

  Future<void> _loadSegmentsForCurrentItem() async {
    final item = _queue.currentItem;
    if (item is AggregatedItem) {
      _segmentService = _createSegmentService(item);
      await _segmentService.loadSegments(item.id);
      _loadTrickplayInfo(item);
    }
  }

  void _loadTrickplayInfo(AggregatedItem item) {
    final mediaSourceId = _manager.currentResolution?.mediaSourceId;
    final info = TrickplayInfo.fromItemData(
      item.rawData,
      mediaSourceId: mediaSourceId,
    );
    if (mounted) {
      setState(() {
        _trickplayInfo = info;
        _trickplayMediaSourceId = mediaSourceId;
      });
    }
  }

  void _refreshTrickplayIfNeeded() {
    final item = _queue.currentItem;
    if (item is! AggregatedItem) return;
    final resolvedSourceId = _manager.currentResolution?.mediaSourceId;
    if (resolvedSourceId != null && resolvedSourceId != _trickplayMediaSourceId) {
      _loadTrickplayInfo(item);
    }
  }

  void _onPositionUpdate(Duration position) {
    if (!mounted || _isSeeking || _isRestoringPosition) return;
    _refreshTrickplayIfNeeded();
    _syncAirPlayPlaybackState(position: position);
    _checkSegments(position);
    _checkNextUp(position);
  }

  void _syncAirPlayPlaybackState({Duration? position}) {
    if (_castService.activeKind != CastTargetKind.airPlay) return;
    final pos = position ?? _state.position;
    final ticks = pos.inMicroseconds * 10;
    _nativeAirPlay
        .updateAirPlayPlaybackState(
          isPlaying: _state.isPlaying,
          isBuffering: _state.isBuffering,
          positionTicks: ticks,
        )
        .catchError((_) {});
    _castService.remotePositionNotifier.value = ticks;
    _castService.remoteStateNotifier.value =
        _state.isBuffering ? 'buffering' : (_state.isPlaying ? 'playing' : 'paused');
  }

  void _checkSegments(Duration position) {
    final result = _segmentService.checkPosition(position);
    if (result.shouldSkip && result.skipTo != null) {
      _manager.seekTo(result.skipTo!);
      setState(() {
        _skipSegment = null;
        _skipTo = null;
      });
      return;
    }
    if (result.shouldAsk && result.isNew && result.segment != null) {
      setState(() {
        _skipSegment = result.segment;
        _skipTo = result.skipTo;
      });
    } else if (result.isNone && _skipSegment != null) {
      setState(() {
        _skipSegment = null;
        _skipTo = null;
      });
    }
  }

  void _checkNextUp(Duration position) {
    final nextUpBehavior = _prefs.get(UserPreferences.nextUpBehavior);
    if (nextUpBehavior == NextUpBehavior.disabled || _nextUpDismissed || _showNextUp) return;

    final duration = _state.duration;
    if (duration <= Duration.zero) return;

    final remaining = duration - position;
    final threshold = nextUpBehavior == NextUpBehavior.extended
        ? const Duration(seconds: 1)
        : const Duration(milliseconds: 500);

    final activeSegment = _segmentService.activeSegment;
    final inOutro = activeSegment?.type == MediaSegmentType.outro;
    if (inOutro && remaining > threshold) {
      return;
    }

    if (remaining <= threshold && _queue.hasNext) {
      final nextItem = _queue.peekNext;
      if (nextItem is AggregatedItem) {
        _manager.suppressAutoNext = true;
        setState(() {
          _showNextUp = true;
          _nextUpItem = nextItem;
        });
      }
    }
  }

  Future<void> _handleNextUpPlay() async {
    if (_isNextUpAdvancing) return;
    _isNextUpAdvancing = true;
    setState(() => _showNextUp = false);
    try {
      await _checkStillWatching();
      await _manager.next();
    } finally {
      _isNextUpAdvancing = false;
    }
  }

  void _handleNextUpDismiss() {
    _manager.suppressAutoNext = false;
    setState(() {
      _showNextUp = false;
      _nextUpDismissed = true;
    });
  }

  Future<void> _checkStillWatching() async {
    final behavior = _prefs.get(UserPreferences.stillWatchingBehavior);
    if (behavior == StillWatchingBehavior.disabled) return;
    if (_consecutiveEpisodes < behavior.episodes) return;

    _manager.pause();
    final shouldContinue = await StillWatchingDialog.show(context);
    if (shouldContinue == true) {
      _consecutiveEpisodes = 0;
      _manager.resume();
    } else {
      _exitPlayback();
    }
  }

  void _skipCurrentSegment() {
    if (_skipTo != null) {
      _manager.seekTo(_skipTo!);
    }
    setState(() {
      _skipSegment = null;
      _skipTo = null;
    });
  }

  Future<void> _exitPlayback() async {
    if (_isStopping) return;
    _isStopping = true;
    _pipService.enableAutoPiP(false);
    await _manager.stop();
    if (mounted) Navigator.of(context).pop();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _state.isPlaying) {
        setState(() {
          _controlsVisible = false;
          if (PlatformDetection.isMobile &&
              _prefs.get(UserPreferences.osdLockEnabled)) {
            _isOsdLocked = true;
          }
        });
      }
    });
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _toggleControls() {
    if (_isOsdLocked) {
      _showControls();
      return;
    }
    if (_controlsVisible) {
      _hideTimer?.cancel();
      setState(() => _controlsVisible = false);
    } else {
      _showControls();
    }
  }

  void _seekRelative(int ms, {bool showControls = true}) {
    final target = _state.position + Duration(milliseconds: ms);
    final clamped = Duration(
      milliseconds: target.inMilliseconds.clamp(0, _state.duration.inMilliseconds),
    );
    _manager.seekTo(clamped);
    if (showControls) _showControls();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatDelay(double seconds) {
    if (seconds == 0) return 'None';
    return '${seconds >= 0 ? '+' : ''}${(seconds * 1000).round()} ms';
  }

  SubtitleViewConfiguration _buildSubtitleConfig() {
    final textColor = Color(_prefs.get(UserPreferences.subtitlesTextColor));
    final bgColor = Color(_prefs.get(UserPreferences.subtitlesBackgroundColor));
    final prefSize = _prefs.get(UserPreferences.subtitlesTextSize);
    final fontWeight = _prefs.get(UserPreferences.subtitlesTextWeight);
    final offset = _prefs.get(UserPreferences.subtitlesOffsetPosition);

    // Preference size is a scale factor (12-48, default 24 = 1x).
    // Mobile needs larger text due to smaller screens held closer.
    final baseSize = PlatformDetection.isMobile ? 40.0 : 32.0;
    final fontSize = (prefSize / 24.0) * baseSize;

    // Offset 0.0 = bottom edge, 0.5 = halfway up.
    // Mobile: smaller base padding to keep subs near bottom.
    final basePadding = PlatformDetection.isMobile ? 16.0 : 24.0;
    final bottomPadding = basePadding + (offset * MediaQuery.sizeOf(context).height * 0.5);

    return SubtitleViewConfiguration(
      visible: true,
      style: TextStyle(
        height: 1.4,
        fontSize: fontSize,
        color: textColor,
        fontWeight: fontWeight >= 700 ? FontWeight.bold : FontWeight.normal,
        backgroundColor: bgColor,
      ),
      textAlign: TextAlign.center,
      padding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, bottomPadding),
    );
  }

  void _applySubtitleStyle() {
    _backend.configureSubtitleStyle(
      textColor: _prefs.get(UserPreferences.subtitlesTextColor),
      backgroundColor: _prefs.get(UserPreferences.subtitlesBackgroundColor),
      strokeColor: _prefs.get(UserPreferences.subtitleTextStrokeColor),
      fontSize: _prefs.get(UserPreferences.subtitlesTextSize),
      fontWeight: _prefs.get(UserPreferences.subtitlesTextWeight),
      verticalOffset: _prefs.get(UserPreferences.subtitlesOffsetPosition),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.space:
        _state.isPlaying ? _manager.pause() : _manager.resume();
        _showControls();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        _seekRelative(-_prefs.get(UserPreferences.skipBackLength));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _seekRelative(_prefs.get(UserPreferences.skipForwardLength));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _changeVolumeBy(0.05);
        _showControls();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _changeVolumeBy(-0.05);
        _showControls();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.keyI:
        _showStreamInfo();
        _showControls();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        if (PlatformDetection.isDesktop && _isDesktopFullscreen) {
          unawaited(_setDesktopFullscreen(false));
          return KeyEventResult.handled;
        }
        _exitPlayback();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        if (_controlsVisible) {
          _state.isPlaying ? _manager.pause() : _manager.resume();
        } else {
          _showControls();
        }
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInPiP) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [_buildVideoSurface()],
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _exitPlayback();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: _overlayFocus,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: GestureDetector(
            onTap: _toggleControls,
            onDoubleTapDown: PlatformDetection.isMobile && !_isOsdLocked ? _onDoubleTapDown : null,
            onDoubleTap: _handleDoubleTapGesture,
            onVerticalDragStart: PlatformDetection.isMobile && !_isOsdLocked ? _onVerticalDragStart : null,
            onVerticalDragUpdate: PlatformDetection.isMobile && !_isOsdLocked ? _onVerticalDragUpdate : null,
            onPanDown: PlatformDetection.isDesktop ? (_) => _showControls() : null,
            behavior: HitTestBehavior.opaque,
            child: MouseRegion(
              cursor: PlatformDetection.isDesktop && !_controlsVisible
                  ? SystemMouseCursors.none
                  : SystemMouseCursors.basic,
              onHover: (_) {
                if (PlatformDetection.isDesktop) {
                  if (_controlsVisible) {
                    _scheduleHide();
                  } else {
                    _showControls();
                  }
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                _buildVideoSurface(),
                if (_isRestoringPosition)
                  const Positioned.fill(
                    child: ColoredBox(color: Colors.black),
                  ),
                _buildPausedDescriptionOverlay(),
                if (_controlsVisible && !_isOsdLocked) ...[
                  _buildTopOverlay(context),
                  _buildBottomOverlay(context),
                  Positioned.fill(
                    child: Center(
                      child: _buildCenterTransportControls(),
                    ),
                  ),
                ],
                _buildCastMiniBar(),
                _buildBufferingIndicator(),
                _buildVolumeOverlay(),
                if (PlatformDetection.isMobile) _buildBrightnessOverlay(),
                if (PlatformDetection.isMobile) _buildDoubleTapSkipOverlay(),
                if (_isOsdLocked) _buildLockedOverlay(),
                if (_skipSegment != null)
                  SkipSegmentOverlay(
                    segment: _skipSegment!,
                    onSkip: _skipCurrentSegment,
                    onDismiss: () => setState(() {
                      _skipSegment = null;
                      _skipTo = null;
                    }),
                  ),
                  if (_showNextUp && _nextUpItem != null)
                    NextUpOverlay(
                      nextItem: _nextUpItem!,
                      imageUrl: _nextUpItem!.primaryImageTag != null
                          ? _clientForItem(_nextUpItem!).imageApi.getPrimaryImageUrl(
                              _nextUpItem!.id,
                              maxWidth: 400,
                              tag: _nextUpItem!.primaryImageTag,
                            )
                          : null,
                      timeoutMs: _prefs.get(UserPreferences.nextUpTimeout),
                      onPlayNext: _handleNextUpPlay,
                      onDismiss: _handleNextUpDismiss,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxFit _zoomToFit(ZoomMode mode) => switch (mode) {
    ZoomMode.fit => BoxFit.contain,
    ZoomMode.autoCrop => BoxFit.cover,
    ZoomMode.stretch => BoxFit.fill,
  };

  Widget _buildVideoSurface() {
    final size = MediaQuery.sizeOf(context);
    return Positioned.fill(
      child: Video(
        controller: _backend.videoController,
        controls: NoVideoControls,
        width: size.width,
        height: size.height,
        fit: _zoomToFit(_zoomMode),
        fill: Colors.black,
        // Disabled on iOS: we manage background playback via PiP.
        pauseUponEnteringBackgroundMode: !PlatformDetection.isIOS,
        subtitleViewConfiguration: _buildSubtitleConfig(),
      ),
    );
  }

  Widget _buildBufferingIndicator() {
    return StreamBuilder<bool>(
      stream: _state.bufferingStream,
      initialData: _state.isBuffering,
      builder: (context, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return const Center(
          child: CircularProgressIndicator(color: AppColorScheme.accent),
        );
      },
    );
  }

  Widget _buildPausedDescriptionOverlay() {
    if (!_prefs.get(UserPreferences.showDescriptionOnPause)) {
      return const SizedBox.shrink();
    }
    final description = _currentItemDescription();
    if (description == null) return const SizedBox.shrink();
    final title = _currentItemTitle();
    return StreamBuilder<bool>(
      stream: _state.playingStream,
      initialData: _state.isPlaying,
      builder: (context, snap) {
        final isPlaying = snap.data ?? false;
        return Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: isPlaying ? 0.0 : 1.0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.58),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.spaceXl,
                          vertical: AppSpacing.spaceLg,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xCC111111),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.spaceXl),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (title.isNotEmpty)
                                    Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: AppTypography.fontSizeXl,
                                        fontWeight: FontWeight.w700,
                                        height: 1.2,
                                      ),
                                    ),
                                  if (title.isNotEmpty)
                                    const SizedBox(height: AppSpacing.spaceMd),
                                  Text(
                                    description,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: AppTypography.fontSizeLg,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _currentItemTitle() {
    final item = _queue.currentItem;
    if (item is AggregatedItem) {
      return _firstNonEmptyText([item.seriesName, item.name]) ?? '';
    }
    if (item is Map) {
      return _firstNonEmptyText([
        item['SeriesName'] as String?,
        item['Name'] as String?,
      ]) ?? '';
    }
    if (item is String) {
      final meta = _manager.currentOfflineMetadata;
      return _firstNonEmptyText([
        meta?['SeriesName'] as String?,
        meta?['Name'] as String?,
      ]) ?? item.split('/').last;
    }
    return '';
  }

  String? _currentItemDescription() {
    final item = _queue.currentItem;
    if (item is AggregatedItem) {
      return _firstNonEmptyText([item.overview, item.tagline]);
    }
    if (item is Map) {
      return _firstNonEmptyText([
        item['Overview'] as String?,
        (item['Taglines'] as List?)?.firstOrNull as String?,
      ]);
    }
    if (item is String) {
      final meta = _manager.currentOfflineMetadata;
      return _firstNonEmptyText([
        meta?['Overview'] as String?,
        (meta?['Taglines'] as List?)?.firstOrNull as String?,
      ]);
    }
    return null;
  }

  String? _firstNonEmptyText(List<String?> candidates) {
    for (final s in candidates) {
      if (s != null && s.isNotEmpty) return s;
    }
    return null;
  }

  Widget _buildTopOverlay(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: padding.top + AppSpacing.spaceSm,
          left: AppSpacing.spaceLg,
          right: AppSpacing.spaceLg,
          bottom: AppSpacing.spaceMd,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            if (!PlatformDetection.useLeanbackUi)
              IconButton(
                onPressed: _exitPlayback,
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
            const SizedBox(width: AppSpacing.spaceSm),
            Expanded(child: _buildTitleInfo()),
            if (PlatformDetection.isMobile &&
                _prefs.get(UserPreferences.osdLockEnabled))
              IconButton(
                onPressed: () {
                  _hideTimer?.cancel();
                  setState(() {
                    _controlsVisible = false;
                    _isOsdLocked = true;
                  });
                },
                icon: const Icon(Icons.lock_outline, color: Colors.white, size: 22),
              ),
            _buildClock(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleInfo() {
    final item = _queue.currentItem;
    if (item == null) return const SizedBox.shrink();

    final String title;
    final String? seriesName;
    final String? episodeInfo;
    if (item is AggregatedItem) {
      title = item.name;
      seriesName = item.seriesName;
      episodeInfo = item.indexNumber != null
          ? 'S${item.parentIndexNumber ?? '?'}:E${item.indexNumber}'
          : null;
    } else if (item is Map) {
      title = (item['Name'] ?? '') as String;
      seriesName = item['SeriesName'] as String?;
      episodeInfo = item['IndexNumber'] != null
          ? 'S${item['ParentIndexNumber'] ?? '?'}:E${item['IndexNumber']}'
          : null;
    } else if (item is String) {
      final meta = _manager.currentOfflineMetadata;
      title = (meta?['Name'] as String?) ?? item.split('/').last;
      seriesName = meta?['SeriesName'] as String?;
      final idx = meta?['IndexNumber'] as int?;
      final parentIdx = meta?['ParentIndexNumber'] as int?;
      episodeInfo =
          idx != null ? 'S${parentIdx ?? '?'}:E$idx' : null;
    } else {
      title = item.toString();
      seriesName = null;
      episodeInfo = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (seriesName != null)
          Text(
            seriesName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: AppTypography.fontSizeSm,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        Text(
          [if (episodeInfo != null) episodeInfo, title]
              .where((s) => s.isNotEmpty)
              .join(' — '),
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppTypography.fontSizeLg,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildClock() {
    final behavior = _prefs.get(UserPreferences.clockBehavior);
    if (behavior == ClockBehavior.never || behavior == ClockBehavior.inMenus) {
      return const SizedBox.shrink();
    }
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 30)),
      builder: (context, _) {
        final now = DateTime.now();
        final h = now.hour;
        final m = now.minute.toString().padLeft(2, '0');
        return Text(
          '$h:$m',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: AppTypography.fontSizeMd,
          ),
        );
      },
    );
  }

  Widget _buildCastMiniBar() {
    return ValueListenableBuilder<CastTargetKind?>(
      valueListenable: _castService.activeKindNotifier,
      builder: (context, kind, _) {
        if (kind == null) return const SizedBox.shrink();

        final label = switch (kind) {
          CastTargetKind.googleCast => 'Casting to Google Cast',
          CastTargetKind.airPlay => 'Casting via AirPlay',
          CastTargetKind.dlna => 'Casting via DLNA',
          CastTargetKind.jellyfinSession => 'Remote Playback',
        };

        final stateLabel = _remotePlaybackState == null
            ? ''
            : ' · ${_remotePlaybackState![0].toUpperCase()}${_remotePlaybackState!.substring(1)}';
        final positionLabel = _remotePositionTicks > 0
            ? ' · ${_formatDuration(Duration(microseconds: _remotePositionTicks ~/ 10))}'
            : '';

        return Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showCastControls,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cast_connected, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '$label$stateLabel$positionLabel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppTypography.fontSizeXs,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomOverlay(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: padding.bottom + AppSpacing.spaceSm,
          left: AppSpacing.spaceLg,
          right: AppSpacing.spaceLg,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSeekbar(),
            const SizedBox(height: AppSpacing.spaceXs),
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSeekbar() {
    return StreamBuilder<Duration>(
      stream: _state.positionStream,
      initialData: _state.position,
      builder: (context, posSnap) {
        return StreamBuilder<Duration>(
          stream: _state.durationStream,
          initialData: _state.duration,
          builder: (context, durSnap) {
            final position = posSnap.data ?? Duration.zero;
            final duration = durSnap.data ?? Duration.zero;
            final durationMs = math.max(duration.inMilliseconds, 1).toDouble();
            final double positionMs = _isSeeking
                ? _seekValue
                : position.inMilliseconds.clamp(0, duration.inMilliseconds).toDouble();
            final seekPosition = Duration(milliseconds: positionMs.round());
            final trickplayTile = _isSeeking ? _getTrickplayTile(seekPosition) : null;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trickplayTile != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.spaceSm),
                    child: _buildSeekPreviewThumbnail(
                      imageUrl: trickplayTile.url,
                      headers: trickplayTile.headers,
                      position: seekPosition,
                      sourceRect: trickplayTile.sourceRect,
                      thumbWidth: trickplayTile.thumbWidth,
                      thumbHeight: trickplayTile.thumbHeight,
                      tileWidth: trickplayTile.tileWidth,
                      tileHeight: trickplayTile.tileHeight,
                    ),
                  ),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: AppColorScheme.rangeProgress,
                    inactiveTrackColor: AppColorScheme.rangeTrack,
                    thumbColor: AppColorScheme.rangeThumb,
                    overlayColor: AppColorScheme.rangeThumb.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: positionMs.clamp(0.0, durationMs),
                    max: durationMs,
                    onChangeStart: (v) {
                      setState(() {
                        _isSeeking = true;
                        _seekValue = v;
                      });
                      _hideTimer?.cancel();
                    },
                    onChanged: (v) {
                      setState(() => _seekValue = v);
                    },
                    onChangeEnd: (v) {
                      _isSeeking = false;
                      _manager.seekTo(Duration(milliseconds: v.round()));
                      _scheduleHide();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spaceLg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_isSeeking
                            ? Duration(milliseconds: _seekValue.round())
                            : position),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: AppTypography.fontSizeXs,
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: AppTypography.fontSizeXs,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSeekPreviewThumbnail({
    required String imageUrl,
    required Map<String, String> headers,
    required Duration position,
    required Rect sourceRect,
    required double thumbWidth,
    required double thumbHeight,
    required int tileWidth,
    required int tileHeight,
  }) {
    final displayWidth = 220.0;
    final displayHeight = displayWidth * (thumbHeight / thumbWidth);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: displayWidth,
          height: displayHeight,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tileW = thumbWidth * tileWidth;
                final tileH = thumbHeight * tileHeight;
                final scaleX = constraints.maxWidth / thumbWidth;
                final scaleY = constraints.maxHeight / thumbHeight;
                return OverflowBox(
                  maxWidth: tileW * scaleX,
                  maxHeight: tileH * scaleY,
                  alignment: Alignment(
                    tileWidth <= 1
                        ? 0.0
                        : -1.0 +
                            2.0 *
                                sourceRect.left /
                                (tileW - thumbWidth),
                    tileHeight <= 1
                        ? 0.0
                        : -1.0 +
                            2.0 *
                                sourceRect.top /
                                (tileH - thumbHeight),
                  ),
                  child: Image.network(
                    imageUrl,
                    headers: headers.isEmpty ? null : headers,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white.withValues(alpha: 0.08),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.movie,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.spaceXs),
        Text(
          _formatDuration(position),
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppTypography.fontSizeXs,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  ({String url, Map<String, String> headers, Rect sourceRect, double thumbWidth, double thumbHeight, int tileWidth, int tileHeight})? _getTrickplayTile(Duration position) {
    if (!_prefs.get(UserPreferences.trickPlayEnabled)) return null;

    final info = _trickplayInfo;
    if (info == null || !info.isValid) return null;

    final item = _queue.currentItem;
    if (item is! AggregatedItem) return null;

    final positionMs = position.inMilliseconds;
    final tileIndex = positionMs ~/ info.interval;
    final tilesPerImage = info.tilesPerImage;
    final tileOffset = tileIndex % tilesPerImage;
    final imageIndex = tileIndex ~/ tilesPerImage;

    final col = tileOffset % info.tileWidth;
    final row = tileOffset ~/ info.tileWidth;
    final offsetX = (col * info.width).toDouble();
    final offsetY = (row * info.height).toDouble();

    final trickplayClient = _clientForItem(item);
    final url = trickplayClient.imageApi.getTrickplayTileImageUrl(
      item.id,
      width: info.width,
      index: imageIndex,
      mediaSourceId: _trickplayMediaSourceId,
    );
    final token = trickplayClient.accessToken;
    final headers = <String, String>{
      if (token != null && token.isNotEmpty)
        'Authorization': 'MediaBrowser Token="$token"',
    };

    return (
      url: url,
      headers: headers,
      sourceRect: Rect.fromLTWH(offsetX, offsetY, info.width.toDouble(), info.height.toDouble()),
      thumbWidth: info.width.toDouble(),
      thumbHeight: info.height.toDouble(),
      tileWidth: info.tileWidth,
      tileHeight: info.tileHeight,
    );
  }

  Widget _buildControlButtons() {
    return ValueListenableBuilder<CastTargetKind?>(
      valueListenable: _castService.activeKindNotifier,
      builder: (context, activeCastKind, _) {
        final item = _queue.currentItem;
        final hasChapters = item is AggregatedItem && item.chapters.isNotEmpty;
        final hasCast = item is AggregatedItem && item.people.isNotEmpty;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        final secondaryIconSize = isLandscape ? 28.0 : 24.0;
        final secondaryExtent = isLandscape ? 56.0 : 48.0;
        final secondaryTextSize =
            isLandscape ? AppTypography.fontSizeMd : AppTypography.fontSizeSm;

        final secondaryButtons = <Widget>[
          _buildSpeedButton(extent: secondaryExtent, textSize: secondaryTextSize),
          if (hasChapters)
            _controlButton(
              Icons.bookmark_outline_rounded,
              onPressed: _showChapters,
              size: secondaryIconSize,
              extent: secondaryExtent,
            ),
          _controlButton(
            Icons.subtitles_outlined,
            onPressed: () => _showTrackSelector(audio: false),
            size: secondaryIconSize,
            extent: secondaryExtent,
          ),
          _controlButton(
            Icons.audiotrack_outlined,
            onPressed: () => _showTrackSelector(audio: true),
            size: secondaryIconSize,
            extent: secondaryExtent,
          ),
          _controlButton(
            Icons.timer_outlined,
            onPressed: () => _showDelayAdjuster(audio: false),
            size: secondaryIconSize,
            extent: secondaryExtent,
          ),
          _controlButton(
            Icons.schedule_rounded,
            onPressed: () => _showDelayAdjuster(audio: true),
            size: secondaryIconSize,
            extent: secondaryExtent,
          ),
          if (hasCast)
            _controlButton(
              Icons.people_outline_rounded,
              onPressed: _showCast,
              size: secondaryIconSize,
              extent: secondaryExtent,
            ),
          _controlButton(
            Icons.cast,
            onPressed: _castToDevice,
            size: secondaryIconSize,
            extent: secondaryExtent,
          ),
          if (activeCastKind != null)
            _controlButton(
              switch (activeCastKind) {
                CastTargetKind.googleCast => Icons.cast_connected,
                CastTargetKind.airPlay => Icons.airplay,
                _ => Icons.router,
              },
              onPressed: _showCastControls,
              size: secondaryIconSize,
              extent: secondaryExtent,
            ),
          if (_manager.currentResolution?.playMethod == StreamPlayMethod.transcode)
            _buildBitrateButton(
              extent: secondaryExtent,
              iconSize: secondaryIconSize,
            ),
          _buildZoomButton(size: secondaryIconSize, extent: secondaryExtent),
          _controlButton(
            Icons.info_outline_rounded,
            onPressed: _showStreamInfo,
            size: secondaryIconSize,
            extent: secondaryExtent,
          ),
          if (PlatformDetection.isDesktop)
            _controlButton(
              _isDesktopFullscreen
                  ? Icons.fullscreen_exit_rounded
                  : Icons.fullscreen_rounded,
              onPressed: _toggleDesktopFullscreen,
              size: secondaryIconSize,
              extent: secondaryExtent,
            ),
        ];

        final estimatedWidth = secondaryButtons.length * (secondaryExtent + 8);

        return LayoutBuilder(
          builder: (context, constraints) {
            final canFitLandscapeRow =
                isLandscape && estimatedWidth <= constraints.maxWidth;

            if (canFitLandscapeRow) {
              return SizedBox(
                height: secondaryExtent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: secondaryButtons,
                ),
              );
            }

            return SizedBox(
              height: secondaryExtent,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final button in secondaryButtons)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: button,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _syncDesktopFullscreenState() async {
    if (!PlatformDetection.isDesktop) return;
    try {
      final full = await windowManager.isFullScreen();
      if (!mounted) return;
      setState(() => _isDesktopFullscreen = full);
    } catch (_) {}
  }

  Future<void> _setDesktopFullscreen(bool full) async {
    if (!PlatformDetection.isDesktop) return;
    try {
      await windowManager.setFullScreen(full);
      if (!mounted) return;
      setState(() => _isDesktopFullscreen = full);
    } catch (_) {}
  }

  Future<void> _toggleDesktopFullscreen() async {
    if (!PlatformDetection.isDesktop) return;
    try {
      final full = await windowManager.isFullScreen();
      await _setDesktopFullscreen(!full);
    } catch (_) {}
  }

  Future<void> _changeVolumeBy(double delta) async {
    final castKind = _castService.activeKind;
    if (castKind != null) {
      final current = _remoteVolume ?? 1.0;
      final next = (current + delta).clamp(0.0, 1.0);
      await _setRemoteVolume(next);
      return;
    }

    final backend = _manager.backend;
    if (backend == null) return;

    final next = (_playerVolume + (delta * 100.0)).clamp(0.0, 100.0);
    _playerVolume = next;
    await backend.setVolume(next);
    _showVolumeIndicator();
  }

  void _initBrightness() {
    Future.microtask(() async {
      try {
        _brightnessValue =
            await ScreenBrightnessPlatform.instance.application;
      } catch (_) {}
    });
  }

  void _showVolumeIndicator() {
    setState(() => _showVolumeOverlay = true);
    _volumeOverlayTimer?.cancel();
    _volumeOverlayTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showVolumeOverlay = false);
    });
  }

  void _showBrightnessIndicator() {
    setState(() => _showBrightnessOverlay = true);
    _brightnessOverlayTimer?.cancel();
    _brightnessOverlayTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showBrightnessOverlay = false);
    });
  }

  Future<void> _setBrightness(double value) async {
    try {
      await ScreenBrightnessPlatform.instance
          .setApplicationScreenBrightness(value.clamp(0.0, 1.0));
    } catch (_) {}
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapDownPosition = details.localPosition;
  }

  void _handleDoubleTapGesture() {
    if (PlatformDetection.isDesktop) {
      unawaited(_toggleDesktopFullscreen());
      _showControls();
      return;
    }
    if (PlatformDetection.isMobile && !_isOsdLocked) {
      _onDoubleTap();
    }
  }

  void _onDoubleTap() {
    final pos = _doubleTapDownPosition;
    if (pos == null) return;
    _doubleTapDownPosition = null;
    final screenWidth = MediaQuery.sizeOf(context).width;
    _doubleTapSkip(forward: pos.dx >= screenWidth / 2);
  }

  void _doubleTapSkip({required bool forward}) {
    final ms = _prefs.get(forward
        ? UserPreferences.skipForwardLength
        : UserPreferences.skipBackLength);
    _seekRelative(forward ? ms : -ms, showControls: false);
    if (forward) {
      _skipForwardAccum += ms;
      setState(() => _showSkipForward = true);
      _skipForwardTimer?.cancel();
      _skipForwardTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) setState(() { _showSkipForward = false; _skipForwardAccum = 0; });
      });
    } else {
      _skipBackwardAccum += ms;
      setState(() => _showSkipBackward = true);
      _skipBackwardTimer?.cancel();
      _skipBackwardTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted) setState(() { _showSkipBackward = false; _skipBackwardAccum = 0; });
      });
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    _verticalDragIsVolume = details.localPosition.dx > screenWidth / 2;
    _verticalDragStartY = details.localPosition.dy;
    _verticalDragStartValue = _verticalDragIsVolume
        ? _playerVolume / 100.0
        : _brightnessValue;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final deltaY = _verticalDragStartY - details.localPosition.dy;
    final deltaValue = deltaY / (screenHeight * 0.7);

    if (_verticalDragIsVolume) {
      final newVolume = (_verticalDragStartValue + deltaValue).clamp(0.0, 1.0);
      _playerVolume = newVolume * 100.0;
      _manager.backend?.setVolume(_playerVolume);
      _showVolumeIndicator();
    } else {
      final newBrightness =
          (_verticalDragStartValue + deltaValue).clamp(0.0, 1.0);
      _brightnessValue = newBrightness;
      _setBrightness(newBrightness);
      _showBrightnessIndicator();
    }
  }

  Widget _buildVolumeOverlay() {
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _showVolumeOverlay ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          child: Align(
            alignment: const Alignment(0.85, 0.0),
            child: _buildGestureIndicator(
              icon: _playerVolume <= 0
                  ? Icons.volume_off_rounded
                  : _playerVolume < 50
                      ? Icons.volume_down_rounded
                      : Icons.volume_up_rounded,
              value: _playerVolume / 100.0,
              label: '${_playerVolume.round()}%',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrightnessOverlay() {
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _showBrightnessOverlay ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          child: Align(
            alignment: const Alignment(-0.85, 0.0),
            child: _buildGestureIndicator(
              icon: _brightnessValue <= 0.25
                  ? Icons.brightness_low_rounded
                  : _brightnessValue >= 0.75
                      ? Icons.brightness_high_rounded
                      : Icons.brightness_medium_rounded,
              value: _brightnessValue,
              label: '${(_brightnessValue * 100).round()}%',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGestureIndicator({
    required IconData icon,
    required double value,
    required String label,
  }) {
    const barHeight = 120.0;
    final fillHeight = barHeight * value.clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 10),
          SizedBox(
            height: barHeight,
            width: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: Colors.white24),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: fillHeight,
                    child: const ColoredBox(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 40,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoubleTapSkipOverlay() {
    if (!_showSkipForward && !_showSkipBackward) return const SizedBox.shrink();
    final isForward = _showSkipForward;
    final accum = isForward ? _skipForwardAccum : _skipBackwardAccum;
    final seconds = accum ~/ 1000;
    if (seconds <= 0) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: isForward
              ? const Alignment(0.6, 0.0)
              : const Alignment(-0.6, 0.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isForward
                      ? Icons.fast_forward_rounded
                      : Icons.fast_rewind_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 4),
                Text(
                  '$seconds seconds',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showControls,
        child: SafeArea(
          child: Center(
            child: IgnorePointer(
              ignoring: !_controlsVisible,
              child: AnimatedOpacity(
                opacity: _controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onLongPress: () {
                    setState(() => _isOsdLocked = false);
                    _showControls();
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, color: Colors.white70, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Long press to unlock',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterTransportControls() {
    return StreamBuilder<bool>(
      stream: _state.playingStream,
      initialData: _state.isPlaying,
      builder: (context, snap) {
        final isPlaying = snap.data ?? false;

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_queue.hasPrevious)
              _controlButton(
                Icons.skip_previous_rounded,
                onPressed: _manager.previous,
                size: 40,
                extent: 72,
              ),
            _controlButton(
              Icons.replay_10_rounded,
              onPressed: () => _seekRelative(
                  -_prefs.get(UserPreferences.skipBackLength)),
              size: 46,
              extent: 78,
            ),
            _controlButton(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              onPressed: () =>
                  isPlaying ? _manager.pause() : _manager.resume(),
              size: 64,
              extent: 92,
            ),
            _controlButton(
              Icons.forward_30_rounded,
              onPressed: () => _seekRelative(
                  _prefs.get(UserPreferences.skipForwardLength)),
              size: 46,
              extent: 78,
            ),
            if (_queue.hasNext)
              _controlButton(
                Icons.skip_next_rounded,
                onPressed: _manager.next,
                size: 40,
                extent: 72,
              ),
          ],
        );
      },
    );
  }

  Widget _controlButton(
    IconData icon, {
    required VoidCallback onPressed,
    double size = 24,
    double extent = 48,
  }) {
    return SizedBox(
      width: extent,
      height: extent,
      child: IconButton(
        onPressed: () {
          onPressed();
          _showControls();
        },
        icon: Icon(icon, color: Colors.white, size: size),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildSpeedButton({
    double extent = 48,
    double textSize = AppTypography.fontSizeSm,
  }) {
    return SizedBox(
      width: extent,
      height: extent,
      child: PopupMenuButton<double>(
        onSelected: (speed) {
          _manager.setPlaybackSpeed(speed);
          _showControls();
        },
        offset: const Offset(0, -200),
        color: AppColorScheme.surface,
        itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
            .map((s) => PopupMenuItem(
                  value: s,
                  child: Text(
                    '${s}x',
                    style: TextStyle(
                      color: _state.playbackSpeed == s
                          ? AppColorScheme.accent
                          : Colors.white,
                    ),
                  ),
                ))
            .toList(),
        child: Center(
          child: Text(
            '${_state.playbackSpeed}x',
            style: TextStyle(
              color: Colors.white,
              fontSize: textSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBitrateButton({
    double extent = 48,
    double iconSize = 24,
  }) {
    // null means auto (profile default)
    final options = <int?>[null, 40, 20, 12, 8, 4, 2];
    final current = _manager.maxBitrateOverrideMbps;

    String label(int? mbps) => mbps == null ? 'Auto' : '$mbps Mbps';

    return SizedBox(
      width: extent,
      height: extent,
      child: PopupMenuButton<int?>(
        onSelected: (mbps) {
          _manager.changeBitrate(mbps);
          _showControls();
        },
        offset: const Offset(0, -280),
        color: AppColorScheme.surface,
        itemBuilder: (_) => options
            .map((mbps) => PopupMenuItem(
                  value: mbps,
                  child: Text(
                    label(mbps),
                    style: TextStyle(
                      color: current == mbps
                          ? AppColorScheme.accent
                          : Colors.white,
                    ),
                  ),
                ))
            .toList(),
        child: Center(
          child: Icon(
            Icons.high_quality_outlined,
            color: current != null ? AppColorScheme.accent : Colors.white,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  void _showTrackSelector({required bool audio}) {
    final resolution = _manager.currentResolution;
    final streamType = audio ? 'Audio' : 'Subtitle';
    final offlineMeta = _manager.currentOfflineMetadata;
    final allStreams = resolution?.mediaStreams
      ?? (offlineMeta?['MediaStreams'] as List?)?.cast<Map<String, dynamic>>()
      ?? const <Map<String, dynamic>>[];
    final streams = allStreams
        .where((s) => s['Type'] == streamType)
        .toList();

    final int? currentStreamIndex;
    if (audio) {
      currentStreamIndex = _manager.audioStreamIndex ??
          streams.where((s) => s['IsDefault'] == true).firstOrNull?['Index'] as int?;
    } else {
      final subIdx = _manager.subtitleStreamIndex;
      currentStreamIndex = subIdx ?? // null = server default
          streams.where((s) => s['IsDefault'] == true).firstOrNull?['Index'] as int?;
    }
    final isSubsOff = !audio && _manager.subtitleStreamIndex == -1;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColorScheme.surface,
      isScrollControlled: true,
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.spaceLg),
                child: Text(
                  audio ? 'Audio' : 'Subtitles',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.fontSizeLg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (!audio)
                      ListTile(
                        title: const Text('Off',
                            style: TextStyle(color: Colors.white)),
                        leading: Icon(
                          Icons.radio_button_checked,
                          color: isSubsOff || (currentStreamIndex == null && streams.isNotEmpty)
                              ? AppColorScheme.accent
                              : Colors.white38,
                        ),
                        onTap: () {
                          _manager.disableSubtitles();
                          Navigator.pop(sheetCtx);
                        },
                      ),
                    ...streams.asMap().entries.map((e) {
                      final stream = e.value;
                      final streamIndex = stream['Index'] as int? ?? e.key;
                      final displayTitle = stream['DisplayTitle'] as String?;
                      final title = stream['Title'] as String?;
                      final language = stream['Language'] as String?;
                      final codec = stream['Codec'] as String?;

                      final label = displayTitle ??
                          title ??
                          language ??
                          '$streamType ${e.key + 1}';
                      final subtitle = [
                        if (language != null && displayTitle != null) language,
                        if (codec != null) codec.toUpperCase(),
                        if (stream['Channels'] != null) '${stream['Channels']}ch',
                      ].join(' · ');

                      final selected = !isSubsOff && currentStreamIndex == streamIndex;

                      return ListTile(
                        title: Text(label,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: subtitle.isNotEmpty
                            ? Text(subtitle,
                                style: const TextStyle(color: Colors.white54))
                            : null,
                        leading: Icon(
                          Icons.radio_button_checked,
                          color: selected
                              ? AppColorScheme.accent
                              : Colors.white38,
                        ),
                        onTap: () {
                          if (audio) {
                            _manager.changeAudioTrack(streamIndex);
                          } else {
                            _manager.changeSubtitleTrack(streamIndex);
                          }
                          Navigator.pop(sheetCtx);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    _showControls();
  }

  Widget _buildZoomButton({
    double size = 24,
    double extent = 48,
  }) {
    final icon = switch (_zoomMode) {
      ZoomMode.fit => Icons.fit_screen_rounded,
      ZoomMode.autoCrop => Icons.crop_rounded,
      ZoomMode.stretch => Icons.open_in_full_rounded,
    };
    return _controlButton(
      icon,
      size: size,
      extent: extent,
      onPressed: () {
        final modes = ZoomMode.values;
        final next = modes[(_zoomMode.index + 1) % modes.length];
        setState(() => _zoomMode = next);
        _prefs.set(UserPreferences.playerZoomMode, next);
      },
    );
  }

  void _showChapters() {
    final item = _queue.currentItem;
    if (item is! AggregatedItem) return;
    final chapters = item.chapters;
    if (chapters.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColorScheme.surface,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.spaceLg),
              child: Text(
                'Chapters',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppTypography.fontSizeLg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: chapters.length,
                itemBuilder: (ctx, i) {
                  final ch = chapters[i];
                  final name = (ch['Name'] as String?) ?? 'Chapter ${i + 1}';
                  final ticks = ch['StartPositionTicks'] as int? ?? 0;
                  final pos = Duration(microseconds: ticks ~/ 10);
                  return ListTile(
                    title: Text(name, style: const TextStyle(color: Colors.white)),
                    trailing: Text(
                      _formatDuration(pos),
                      style: const TextStyle(color: Colors.white54),
                    ),
                    onTap: () {
                      _manager.seekTo(pos);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    _showControls();
  }

  void _showCast() {
    final item = _queue.currentItem;
    if (item is! AggregatedItem) return;
    final people = item.people;
    if (people.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColorScheme.surface,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.spaceLg),
              child: Text(
                'Cast & Crew',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppTypography.fontSizeLg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: people.length,
                itemBuilder: (ctx, i) {
                  final person = people[i];
                  final name = (person['Name'] as String?) ?? '';
                  final role = person['Role'] as String?;
                  final type = person['Type'] as String?;
                  final subtitle = role ?? type ?? '';
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.white12,
                      child: Icon(Icons.person, color: Colors.white54),
                    ),
                    title: Text(name, style: const TextStyle(color: Colors.white)),
                    subtitle: subtitle.isNotEmpty
                        ? Text(subtitle, style: const TextStyle(color: Colors.white54))
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    _showControls();
  }

  Future<void> _castToDevice() async {
    final item = _queue.currentItem;
    if (item is! AggregatedItem) return;
    final positionTicks = _state.position.inMicroseconds * 10;
    final startIndex = _queue.currentIndex < 0 ? 0 : _queue.currentIndex;
    final queueItems =
        _queue.items
            .skip(startIndex)
            .whereType<AggregatedItem>()
            .toList(growable: false);
    await showRemotePlayToSessionDialog(
      context,
      item: item,
      queueItems: queueItems.length > 1 ? queueItems : null,
      startPositionTicks: positionTicks,
      audioStreamIndex: _manager.audioStreamIndex,
      subtitleStreamIndex: _manager.subtitleStreamIndex,
    );
    if (mounted) {
      setState(() {});
    }
    _showControls();
  }

  void _showCastControls() {
    final kind = _castService.activeKind;
    if (kind == null) return;

    _refreshRemoteVolume();

    final label = switch (kind) {
      CastTargetKind.googleCast => 'Google Cast',
      CastTargetKind.airPlay => 'AirPlay',
      CastTargetKind.dlna => 'DLNA',
      _ => 'Cast',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColorScheme.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                '$label Controls',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: _remotePlaybackState != null
                  ? Text(
                      '${_remotePlaybackState![0].toUpperCase()}${_remotePlaybackState!.substring(1)}'
                      ' · ${_formatDuration(Duration(microseconds: _remotePositionTicks ~/ 10))}',
                      style: const TextStyle(color: Colors.white54),
                    )
                  : null,
            ),
              if (kind == CastTargetKind.googleCast || kind == CastTargetKind.dlna)
                ListTile(
                  leading: const Icon(Icons.volume_up_rounded, color: Colors.white),
                  title: const Text('Device Volume', style: TextStyle(color: Colors.white)),
                  subtitle: _remoteVolume == null
                      ? const Text('Unavailable', style: TextStyle(color: Colors.white54))
                      : SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColorScheme.accent,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                            overlayColor: Colors.white24,
                          ),
                          child: Slider(
                            value: _remoteVolume!.clamp(0.0, 1.0),
                            min: 0,
                            max: 1,
                            onChanged: (value) => _setRemoteVolume(value),
                          ),
                        ),
                  trailing: _remoteVolume == null
                      ? null
                      : Text(
                          '${(_remoteVolume! * 100).round()}%',
                          style: const TextStyle(color: Colors.white70),
                        ),
                ),
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              title: const Text('Play', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(ctx).pop();
                _runCastAction((k) => _castService.play(k));
              },
            ),
            ListTile(
              leading: const Icon(Icons.pause_rounded, color: Colors.white),
              title: const Text('Pause', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(ctx).pop();
                _runCastAction((k) => _castService.pause(k));
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync_rounded, color: Colors.white),
              title: const Text('Sync Position', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(ctx).pop();
                final positionTicks = _state.position.inMicroseconds * 10;
                _runCastAction(
                  (k) => _castService.seek(k, positionTicks: positionTicks),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.stop_rounded, color: Colors.white),
              title: Text('Stop $label', style: const TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(ctx).pop();
                _runCastAction((k) => _castService.stop(k));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runCastAction(
    Future<void> Function(CastTargetKind kind) action,
  ) async {
    final kind = _castService.activeKind;
    if (kind == null || !mounted) return;

    try {
      await action(kind);
    } catch (e) {
      if (!mounted) return;
      final label = switch (kind) {
        CastTargetKind.googleCast => 'Google Cast',
        CastTargetKind.airPlay => 'AirPlay',
        CastTargetKind.dlna => 'DLNA',
        _ => 'Cast',
      };
      _showThrottledCastError('$label action failed: $e');
    }
  }

  void _showDelayAdjuster({required bool audio}) {
    double delay = audio ? _audioDelay : _subtitleDelay;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColorScheme.surface,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spaceLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  audio ? 'Audio Delay' : 'Subtitle Delay',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.fontSizeLg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceLg),
                Text(
                  _formatDelay(delay),
                  style: const TextStyle(
                    color: AppColorScheme.accent,
                    fontSize: AppTypography.fontSizeLg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.spaceMd),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        delay = ((delay - 0.1) * 10).roundToDouble() / 10;
                        setSheetState(() {});
                        _applyDelay(audio: audio, delay: delay);
                      },
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: AppSpacing.spaceSm),
                    Text('-100ms', style: const TextStyle(color: Colors.white54, fontSize: AppTypography.fontSizeXs)),
                    const SizedBox(width: AppSpacing.spaceLg),
                    OutlinedButton(
                      onPressed: () {
                        delay = 0.0;
                        setSheetState(() {});
                        _applyDelay(audio: audio, delay: delay);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                      ),
                      child: const Text('Reset',
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: AppSpacing.spaceLg),
                    Text('+100ms', style: const TextStyle(color: Colors.white54, fontSize: AppTypography.fontSizeXs)),
                    const SizedBox(width: AppSpacing.spaceSm),
                    IconButton(
                      onPressed: () {
                        delay = ((delay + 0.1) * 10).roundToDouble() / 10;
                        setSheetState(() {});
                        _applyDelay(audio: audio, delay: delay);
                      },
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 32),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.spaceMd),
              ],
            ),
          ),
        ),
      ),
    );
    _showControls();
  }

  void _applyDelay({required bool audio, required double delay}) {
    if (audio) {
      _audioDelay = delay;
      _manager.backend?.setAudioDelay(delay);
    } else {
      _subtitleDelay = delay;
      _manager.backend?.setSubtitleDelay(delay);
    }
  }

  String _formatBitrate(int? bitrate) {
    if (bitrate == null) return 'Unknown';
    if (bitrate >= 1000000) return '${(bitrate / 1000000).toStringAsFixed(1)} Mbps';
    if (bitrate >= 1000) return '${(bitrate / 1000).toStringAsFixed(0)} Kbps';
    return '$bitrate bps';
  }

  String _formatVideoCodec(Map<String, dynamic> stream) {
    var codec = switch (((stream['Codec'] as String?) ?? '').toUpperCase()) {
      'HEVC' => 'HEVC (H.265)',
      'H264' || 'AVC' => 'AVC (H.264)',
      final c => c,
    };

    final profile = stream['Profile'] as String?;
    if (profile != null) codec += ' $profile';
    final level = stream['Level'] as num?;
    if (level != null) codec += '@L$level';
    return codec;
  }

  String _formatAudioCodec(Map<String, dynamic> stream) {
    final label = audioLabelFromProfileCodec(
      stream['Profile'] as String?,
      stream['Codec'] as String?,
    );
    final codec = ((stream['Codec'] as String?) ?? '').toUpperCase();
    if (label == 'Atmos') {
      return 'Atmos';
    }
    return switch (codec) {
      'EAC3' => 'E-AC3 (Dolby Digital Plus)',
      'AC3' => 'AC3 (Dolby Digital)',
      'TRUEHD' => 'TrueHD',
      _ => codec,
    };
  }

  String _formatChannels(int? channels) {
    if (channels == null) return 'Unknown';
    return switch (channels) {
      8 => '7.1',
      6 => '5.1',
      2 => 'Stereo',
      1 => 'Mono',
      _ => '${channels}ch',
    };
  }

  String _getHdrType(Map<String, dynamic> stream) {
    final rangeType = stream['VideoRangeType'] as String? ?? '';
    if (rangeType.contains('DOVI') || rangeType.contains('DoVi')) return 'Dolby Vision';
    if (rangeType.contains('HDR10Plus') || rangeType.contains('HDR10+')) return 'HDR10+';
    if (rangeType.contains('HDR10') || rangeType.contains('HDR')) return 'HDR10';
    if (rangeType.contains('HLG')) return 'HLG';
    final range = stream['VideoRange'] as String?;
    if (range == 'HDR') return 'HDR';
    return 'SDR';
  }

  void _showStreamInfo() {
    final resolution = _manager.currentResolution;
    final playMethod = resolution?.playMethod;
    final methodLabel = _manager.isOfflinePlayback
        ? 'Direct Play'
        : switch (playMethod) {
            StreamPlayMethod.directPlay => 'Direct Play',
            StreamPlayMethod.directStream => 'Direct Stream',
            StreamPlayMethod.transcode => 'Transcoding',
            _ => 'Unknown',
          };

    final item = _queue.currentItem;
    Map<String, dynamic>? mediaSource;
    Map<String, dynamic>? videoStream;
    Map<String, dynamic>? audioStream;
    Map<String, dynamic>? subtitleStream;

    Map<String, dynamic>? pickStream(
      List<Map<String, dynamic>> streams,
      String type,
      int? preferredIndex,
    ) {
      if (preferredIndex != null && preferredIndex >= 0) {
        final preferred = streams
            .where((s) => s['Type'] == type)
            .firstWhere(
              (s) => s['Index'] == preferredIndex,
              orElse: () => const <String, dynamic>{},
            );
        if (preferred.isNotEmpty) {
          return preferred;
        }
      }

      return streams
              .where((s) => s['Type'] == type && s['IsDefault'] == true)
              .firstOrNull ??
          streams.where((s) => s['Type'] == type).firstOrNull;
    }

    void populateStreams(List<Map<String, dynamic>> streams) {
      videoStream = streams.where((s) => s['Type'] == 'Video').firstOrNull;
      audioStream = pickStream(streams, 'Audio', _manager.audioStreamIndex);
      subtitleStream = _manager.subtitleStreamIndex == -1
          ? null
          : pickStream(streams, 'Subtitle', _manager.subtitleStreamIndex);
    }

    if (item is AggregatedItem) {
      final streams = resolution?.mediaStreams ?? item.mediaStreams;
      populateStreams(streams);

      final sourceId = resolution?.mediaSourceId;
      final sources = item.mediaSources;
      if (sourceId != null && sources.isNotEmpty) {
        mediaSource = sources.firstWhere(
          (s) => s['Id'] == sourceId,
          orElse: () => sources.first,
        );
      } else if (sources.isNotEmpty) {
        mediaSource = sources.first;
      }
    } else if (item is String) {
      final meta = _manager.currentOfflineMetadata;
      if (meta != null) {
        final streams = (meta['MediaStreams'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        populateStreams(streams);
        final sources = meta['MediaSources'] as List?;
        if (sources != null && sources.isNotEmpty) {
          mediaSource = sources.first as Map<String, dynamic>?;
        }
      }
    }

    const headerStyle = TextStyle(
      color: Colors.white,
      fontSize: AppTypography.fontSizeMd,
      fontWeight: FontWeight.w600,
    );
    const labelStyle = TextStyle(color: Colors.white54, fontSize: 13);
    const valueStyle = TextStyle(color: Colors.white, fontSize: 13);
    const highlightValue = TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );

    Widget infoRow(String label, String value, {bool highlight = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spaceLg,
          vertical: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: labelStyle),
            Flexible(
              child: Text(
                value,
                style: highlight ? highlightValue : valueStyle,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );
    }

    Widget sectionHeader(String title) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spaceLg, AppSpacing.spaceMd, AppSpacing.spaceLg, 4,
        ),
        child: Text(title, style: headerStyle),
      );
    }

    final container = (mediaSource?['Container'] as String?)?.toUpperCase() ?? 'Unknown';
    final bitrate = mediaSource?['Bitrate'] as int?;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColorScheme.surface,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (ctx, scrollController) => SafeArea(
          child: ListView(
            controller: scrollController,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.spaceLg),
                child: Text(
                  'Playback Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.fontSizeLg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              sectionHeader('Playback'),
              infoRow('Play Method', methodLabel, highlight: true),
              if (resolution != null &&
                  playMethod == StreamPlayMethod.transcode &&
                  resolution.transcodingReasons.isNotEmpty)
                infoRow(
                  'Transcode Reasons',
                  resolution.transcodingReasons
                      .map((r) => r.replaceAllMapped(_camelCaseSpaceRe, (_) => ' '))
                      .join(', '),
                ),
              infoRow('Player', 'media_kit (libmpv)'),
              infoRow('Container', container),
              infoRow('Bitrate', _formatBitrate(bitrate)),

              if (videoStream case final video?) ...[
                sectionHeader('Video'),
                infoRow(
                  'Resolution',
                  '${video['Width']}×${video['Height']}'
                  '${video['RealFrameRate'] != null ? ' @ ${(video['RealFrameRate'] as num).round()}fps' : ''}',
                ),
                infoRow('HDR', _getHdrType(video)),
                infoRow('Codec', _formatVideoCodec(video)),
                if (video['BitRate'] != null)
                  infoRow('Video Bitrate', _formatBitrate(video['BitRate'] as int?)),
              ],

              if (audioStream case final audio?) ...[
                sectionHeader('Audio'),
                infoRow('Track', audio['DisplayTitle'] as String?
                    ?? audio['Language'] as String?
                    ?? 'Unknown'),
                infoRow('Codec', _formatAudioCodec(audio)),
                infoRow('Channels', _formatChannels(audio['Channels'] as int?)),
                if (audio['BitRate'] != null)
                  infoRow('Audio Bitrate', _formatBitrate(audio['BitRate'] as int?)),
                if (audio['SampleRate'] != null)
                  infoRow('Sample Rate', '${((audio['SampleRate'] as num) / 1000).toStringAsFixed(1)} kHz'),
              ],

              if (subtitleStream case final subtitle?) ...[
                sectionHeader('Subtitles'),
                infoRow('Track', subtitle['DisplayTitle'] as String?
                    ?? subtitle['Language'] as String?
                    ?? 'Unknown'),
                infoRow('Format', ((subtitle['Codec'] as String?) ?? 'Unknown').toUpperCase()),
                infoRow('Type', subtitle['IsExternal'] == true ? 'External' : 'Embedded'),
              ],

              const SizedBox(height: AppSpacing.spaceLg),
            ],
          ),
        ),
      ),
    );
    _showControls();
  }
}
