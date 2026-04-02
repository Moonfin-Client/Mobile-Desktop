import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:jellyfin_design/jellyfin_design.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:playback_core/playback_core.dart';
import 'package:server_core/server_core.dart';

import '../../../data/models/aggregated_item.dart';
import '../../../data/viewmodels/live_tv_guide_view_model.dart';
import '../../../playback/media_kit_player_backend.dart';
import '../../../preference/preference_constants.dart';
import '../../../preference/user_preferences.dart';
import '../../../util/platform_detection.dart';

class LiveTvPlayerScreen extends StatefulWidget {
  final List<GuideChannel> channels;
  final int startIndex;

  const LiveTvPlayerScreen({
    super.key,
    required this.channels,
    required this.startIndex,
  });

  @override
  State<LiveTvPlayerScreen> createState() => _LiveTvPlayerScreenState();
}

class _LiveTvPlayerScreenState extends State<LiveTvPlayerScreen> {
  final _manager = GetIt.instance<PlaybackManager>();
  final _backend = GetIt.instance<MediaKitPlayerBackend>();
  final _client = GetIt.instance<MediaServerClient>();
  final _prefs = GetIt.instance<UserPreferences>();

  late int _currentIndex;
  bool _infoVisible = true;
  Timer? _hideTimer;
  bool _isStopping = false;
  bool _isSwitching = false;

  GuideProgram? _currentProgram;
  Timer? _programRefreshTimer;

  final _overlayFocus = FocusNode();
  PlayerState get _state => _manager.state;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _applySubtitleStyle();
    _playCurrentChannel();
    _scheduleHide();
    _startProgramRefresh();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _programRefreshTimer?.cancel();
    _overlayFocus.dispose();
    if (!_isStopping) {
      _manager.stop();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  GuideChannel get _currentChannel => widget.channels[_currentIndex];

  Future<void> _playCurrentChannel() async {
    final channel = _currentChannel;
    final item = AggregatedItem(
      id: channel.id,
      serverId: _client.baseUrl,
      rawData: channel.rawData,
    );
    try {
      await _manager.playItems([item]);
    } catch (e) {
      debugPrint('[LiveTV] Playback failed for channel ${channel.name}: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to play ${channel.name}')),
        );
      }
      return;
    }
    _fetchCurrentProgram();
  }

  Future<void> _switchChannel(int newIndex) async {
    if (_isSwitching) return;
    _isSwitching = true;
    try {
      setState(() {
        _currentIndex = newIndex;
        _currentProgram = null;
        _infoVisible = true;
      });
      await _playCurrentChannel();
      _scheduleHide();
    } finally {
      _isSwitching = false;
    }
  }

  void _nextChannel() {
    final next = (_currentIndex + 1) % widget.channels.length;
    _switchChannel(next);
  }

  void _previousChannel() {
    final prev = (_currentIndex - 1 + widget.channels.length) %
        widget.channels.length;
    _switchChannel(prev);
  }

  Future<void> _fetchCurrentProgram() async {
    final channelId = _currentChannel.id;
    try {
      final now = DateTime.now();
      final response = await _client.liveTvApi.getGuide(
        startDate: now,
        endDate: now.add(const Duration(minutes: 5)),
        channelIds: [channelId],
        fields: 'Overview',
        enableTotalRecordCount: false,
        userId: _client.userId,
      );
      final items = (response['Items'] as List?) ?? [];
      if (items.isEmpty || !mounted) return;

      final raw = items.first as Map<String, dynamic>;
      final startStr = raw['StartDate'] as String?;
      final endStr = raw['EndDate'] as String?;
      if (startStr == null || endStr == null) return;

      setState(() {
        _currentProgram = GuideProgram(
          id: raw['Id'] as String,
          channelId: channelId,
          name: raw['Name'] as String? ?? '',
          startDate: DateTime.parse(startStr).toLocal(),
          endDate: DateTime.parse(endStr).toLocal(),
          overview: raw['Overview'] as String?,
          episodeTitle: raw['EpisodeTitle'] as String?,
          isMovie: raw['IsMovie'] == true,
          isSeries: raw['IsSeries'] == true,
          isSports: raw['IsSports'] == true,
          isNews: raw['IsNews'] == true,
          isKids: raw['IsKids'] == true,
          isPremiere: raw['IsPremiere'] == true,
          hasTimer: raw['TimerId'] != null,
          rawData: raw,
        );
      });
    } catch (_) {}
  }

  void _startProgramRefresh() {
    _programRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _fetchCurrentProgram(),
    );
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _infoVisible = false);
    });
  }

  void _showInfo() {
    setState(() => _infoVisible = true);
    _scheduleHide();
  }

  void _toggleInfo() {
    if (_infoVisible) {
      _hideTimer?.cancel();
      setState(() => _infoVisible = false);
    } else {
      _showInfo();
    }
  }

  Future<void> _exitPlayback() async {
    if (_isStopping) return;
    _isStopping = true;
    await _manager.stop();
    if (mounted) Navigator.of(context).pop();
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

  SubtitleViewConfiguration _buildSubtitleConfig() {
    final textColor = Color(_prefs.get(UserPreferences.subtitlesTextColor));
    final bgColor = Color(_prefs.get(UserPreferences.subtitlesBackgroundColor));
    final prefSize = _prefs.get(UserPreferences.subtitlesTextSize);
    final fontWeight = _prefs.get(UserPreferences.subtitlesTextWeight);
    final offset = _prefs.get(UserPreferences.subtitlesOffsetPosition);

    final baseSize = PlatformDetection.isMobile ? 40.0 : 32.0;
    final fontSize = (prefSize / 24.0) * baseSize;
    final basePadding = PlatformDetection.isMobile ? 16.0 : 24.0;
    final bottomPadding =
        basePadding + (offset * MediaQuery.sizeOf(context).height * 0.5);

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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _previousChannel();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _nextChannel();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        if (_infoVisible) {
          _state.isPlaying ? _manager.pause() : _manager.resume();
        } else {
          _showInfo();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowRight:
        _showInfo();
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
        if (_infoVisible) {
          _exitPlayback();
        } else {
          _toggleInfo();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: _overlayFocus,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: GestureDetector(
            onTap: _toggleInfo,
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity == null) return;
              if (details.primaryVelocity! < -200) {
                _nextChannel();
              } else if (details.primaryVelocity! > 200) {
                _previousChannel();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: MouseRegion(
              cursor: PlatformDetection.isDesktop && !_infoVisible
                  ? SystemMouseCursors.none
                  : SystemMouseCursors.basic,
              onHover: (_) {
                if (PlatformDetection.isDesktop) {
                  if (_infoVisible) {
                    _scheduleHide();
                  } else {
                    _showInfo();
                  }
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildVideoSurface(),
                  _buildBufferingIndicator(),
                  if (_infoVisible) ...[
                    _buildTopOverlay(),
                    _buildBottomOverlay(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSurface() {
    final size = MediaQuery.sizeOf(context);
    return Positioned.fill(
      child: Video(
        controller: _backend.videoController,
        controls: NoVideoControls,
        width: size.width,
        height: size.height,
        fit: BoxFit.contain,
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

  Widget _buildTopOverlay() {
    final padding = MediaQuery.of(context).padding;
    final channel = _currentChannel;

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
                icon: const Icon(Icons.arrow_back, color: Colors.white,
                    size: 24),
              ),
            const SizedBox(width: AppSpacing.spaceSm),
            if (channel.number != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColorScheme.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  channel.number!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.fontSizeMd,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spaceMd),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    channel.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppTypography.fontSizeLg,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_currentProgram != null)
                    Text(
                      _currentProgram!.name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: AppTypography.fontSizeSm,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (_currentProgram?.hasTimer == true)
              const Padding(
                padding: EdgeInsets.only(left: AppSpacing.spaceSm),
                child: Icon(Icons.fiber_manual_record,
                    color: Colors.red, size: 14),
              ),
            const SizedBox(width: AppSpacing.spaceMd),
            _buildClock(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    if (_currentProgram == null) return const SizedBox.shrink();

    final padding = MediaQuery.of(context).padding;
    final program = _currentProgram!;
    final now = DateTime.now();
    final progress = program.progressAt(now);
    final startTime = _formatTime(program.startDate);
    final endTime = _formatTime(program.endDate);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          bottom: padding.bottom + AppSpacing.spaceSm,
          left: AppSpacing.spaceLg,
          right: AppSpacing.spaceLg,
          top: AppSpacing.spaceMd,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (program.episodeTitle != null)
              Padding(
                padding:
                    const EdgeInsets.only(bottom: AppSpacing.spaceXs),
                child: Text(
                  program.episodeTitle!,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: AppTypography.fontSizeSm),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white24,
                valueColor:
                    const AlwaysStoppedAnimation(AppColorScheme.accent),
                minHeight: 3,
              ),
            ),
            const SizedBox(height: AppSpacing.spaceXs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  startTime,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: AppTypography.fontSizeXs),
                ),
                Text(
                  endTime,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: AppTypography.fontSizeXs),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClock() {
    final behavior = _prefs.get(UserPreferences.clockBehavior);
    if (behavior == ClockBehavior.never ||
        behavior == ClockBehavior.inMenus) {
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

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final amPm = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$h12:$m $amPm';
  }
}
