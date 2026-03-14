import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_design/jellyfin_design.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:playback_core/playback_core.dart';

import '../../../playback/media_kit_player_backend.dart';
import '../../../data/models/aggregated_item.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final _manager = GetIt.instance<PlaybackManager>();
  final _backend = GetIt.instance<MediaKitPlayerBackend>();
  final _prefs = GetIt.instance<UserPreferences>();

  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _isSeeking = false;
  double _seekValue = 0;
  late ZoomMode _zoomMode;
  double _audioDelay = 0.0;
  double _subtitleDelay = 0.0;
  bool _isStopping = false;

  final _overlayFocus = FocusNode();

  PlayerState get _state => _manager.state;
  QueueService get _queue => _manager.queueService;

  @override
  void initState() {
    super.initState();
    _zoomMode = _prefs.get(UserPreferences.playerZoomMode);
    _applySubtitleStyle();
    _scheduleHide();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _overlayFocus.dispose();
    if (!_isStopping) _manager.stop();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  Future<void> _exitPlayback() async {
    if (_isStopping) return;
    _isStopping = true;
    await _manager.stop();
    if (mounted) Navigator.of(context).pop();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _state.isPlaying) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideTimer?.cancel();
      setState(() => _controlsVisible = false);
    } else {
      _showControls();
    }
  }

  void _seekRelative(int ms) {
    final target = _state.position + Duration(milliseconds: ms);
    final clamped = Duration(
      milliseconds: target.inMilliseconds.clamp(0, _state.duration.inMilliseconds),
    );
    _manager.seekTo(clamped);
    _showControls();
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
    final prefSize = _prefs.get(UserPreferences.subtitlesTextSize) as double;
    final fontWeight = _prefs.get(UserPreferences.subtitlesTextWeight) as int;
    final offset = _prefs.get(UserPreferences.subtitlesOffsetPosition) as double;

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
      case LogicalKeyboardKey.arrowLeft:
        _seekRelative(-_prefs.get(UserPreferences.skipBackLength));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _seekRelative(_prefs.get(UserPreferences.skipForwardLength));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        if (_controlsVisible) {
          _state.isPlaying ? _manager.pause() : _manager.resume();
        } else {
          _showControls();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.arrowUp:
        _showControls();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_controlsVisible) {
          _exitPlayback();
        } else {
          _toggleControls();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: _overlayFocus,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: GestureDetector(
            onTap: _toggleControls,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildVideoSurface(),
                if (_controlsVisible) ...[
                  _buildTopOverlay(context),
                  _buildBottomOverlay(context),
                ],
                _buildBufferingIndicator(),
              ],
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
        pauseUponEnteringBackgroundMode: false,
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

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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

  Widget _buildControlButtons() {
    final item = _queue.currentItem;
    final hasChapters = item is AggregatedItem && item.chapters.isNotEmpty;
    final hasCast = item is AggregatedItem && item.people.isNotEmpty;

    return StreamBuilder<bool>(
      stream: _state.playingStream,
      initialData: _state.isPlaying,
      builder: (context, snap) {
        final isPlaying = snap.data ?? false;

        final transportButtons = <Widget>[
          if (_queue.hasPrevious)
            _controlButton(
              Icons.skip_previous_rounded,
              onPressed: _manager.previous,
              size: 28,
            ),
          _controlButton(
            Icons.replay_10_rounded,
            onPressed: () => _seekRelative(
                -_prefs.get(UserPreferences.skipBackLength)),
            size: 32,
          ),
          _controlButton(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            onPressed: () =>
                isPlaying ? _manager.pause() : _manager.resume(),
            size: 48,
          ),
          _controlButton(
            Icons.forward_30_rounded,
            onPressed: () => _seekRelative(
                _prefs.get(UserPreferences.skipForwardLength)),
            size: 32,
          ),
          if (_queue.hasNext)
            _controlButton(
              Icons.skip_next_rounded,
              onPressed: _manager.next,
              size: 28,
            ),
        ];

        final secondaryButtons = <Widget>[
          _buildSpeedButton(),
          if (hasChapters)
            _controlButton(
              Icons.bookmark_outline_rounded,
              onPressed: _showChapters,
            ),
          _controlButton(
            Icons.subtitles_outlined,
            onPressed: () => _showTrackSelector(audio: false),
          ),
          _controlButton(
            Icons.audiotrack_outlined,
            onPressed: () => _showTrackSelector(audio: true),
          ),
          _controlButton(
            Icons.timer_outlined,
            onPressed: () => _showDelayAdjuster(audio: false),
          ),
          _controlButton(
            Icons.schedule_rounded,
            onPressed: () => _showDelayAdjuster(audio: true),
          ),
          if (hasCast)
            _controlButton(
              Icons.people_outline_rounded,
              onPressed: _showCast,
            ),
          if (_manager.currentResolution?.playMethod == StreamPlayMethod.transcode)
            _buildBitrateButton(),
          _buildZoomButton(),
          _controlButton(
            Icons.info_outline_rounded,
            onPressed: _showStreamInfo,
          ),
        ];

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ...transportButtons,
            ...secondaryButtons,
          ],
        );
      },
    );
  }

  Widget _controlButton(
    IconData icon, {
    required VoidCallback onPressed,
    double size = 24,
  }) {
    return SizedBox(
      width: 48,
      height: 48,
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

  Widget _buildSpeedButton() {
    return SizedBox(
      width: 48,
      height: 48,
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTypography.fontSizeSm,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBitrateButton() {
    // null means auto (profile default)
    final options = <int?>[null, 40, 20, 12, 8, 4, 2];
    final current = _manager.maxBitrateOverrideMbps;

    String label(int? mbps) => mbps == null ? 'Auto' : '${mbps} Mbps';

    return SizedBox(
      width: 48,
      height: 48,
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
            size: 24,
          ),
        ),
      ),
    );
  }

  void _showTrackSelector({required bool audio}) {
    final resolution = _manager.currentResolution;
    final streamType = audio ? 'Audio' : 'Subtitle';
    final allStreams = resolution?.mediaStreams ?? const <Map<String, dynamic>>[];
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

  Widget _buildZoomButton() {
    final icon = switch (_zoomMode) {
      ZoomMode.fit => Icons.fit_screen_rounded,
      ZoomMode.autoCrop => Icons.crop_rounded,
      ZoomMode.stretch => Icons.open_in_full_rounded,
    };
    return _controlButton(
      icon,
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
    final codec = ((stream['Codec'] as String?) ?? '').toUpperCase();
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
    final methodLabel = switch (playMethod) {
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

    if (item is AggregatedItem) {
      final streams = resolution?.mediaStreams ?? item.mediaStreams;

      videoStream = streams.where((s) => s['Type'] == 'Video').firstOrNull;
      audioStream = streams.where((s) => s['Type'] == 'Audio' && s['IsDefault'] == true).firstOrNull
                    ?? streams.where((s) => s['Type'] == 'Audio').firstOrNull;
      subtitleStream = streams.where((s) => s['Type'] == 'Subtitle' && s['IsDefault'] == true).firstOrNull;

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
              infoRow('Player', 'media_kit (libmpv)'),
              infoRow('Container', container),
              infoRow('Bitrate', _formatBitrate(bitrate)),

              if (videoStream != null) ...[
                sectionHeader('Video'),
                infoRow(
                  'Resolution',
                  '${videoStream['Width']}×${videoStream['Height']}'
                  '${videoStream['RealFrameRate'] != null ? ' @ ${(videoStream['RealFrameRate'] as num).round()}fps' : ''}',
                ),
                infoRow('HDR', _getHdrType(videoStream)),
                infoRow('Codec', _formatVideoCodec(videoStream)),
                if (videoStream['BitRate'] != null)
                  infoRow('Video Bitrate', _formatBitrate(videoStream['BitRate'] as int?)),
              ],

              if (audioStream != null) ...[
                sectionHeader('Audio'),
                infoRow('Track', audioStream['DisplayTitle'] as String?
                    ?? audioStream['Language'] as String?
                    ?? 'Unknown'),
                infoRow('Codec', _formatAudioCodec(audioStream)),
                infoRow('Channels', _formatChannels(audioStream['Channels'] as int?)),
                if (audioStream['BitRate'] != null)
                  infoRow('Audio Bitrate', _formatBitrate(audioStream['BitRate'] as int?)),
                if (audioStream['SampleRate'] != null)
                  infoRow('Sample Rate', '${((audioStream['SampleRate'] as num) / 1000).toStringAsFixed(1)} kHz'),
              ],

              if (subtitleStream != null) ...[
                sectionHeader('Subtitles'),
                infoRow('Track', subtitleStream['DisplayTitle'] as String?
                    ?? subtitleStream['Language'] as String?
                    ?? 'Unknown'),
                infoRow('Format', ((subtitleStream['Codec'] as String?) ?? 'Unknown').toUpperCase()),
                infoRow('Type', subtitleStream['IsExternal'] == true ? 'External' : 'Embedded'),
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
