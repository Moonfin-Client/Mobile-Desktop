import 'dart:async';

import 'media_stream_resolver.dart';
import 'player_backend.dart';
import 'player_service.dart';
import 'player_state.dart';
import 'queue_service.dart';
import 'stream_resolution_result.dart';

class PlaybackManager {
  PlayerBackend? _backend;
  MediaStreamResolver? _resolver;
  PlayerService? _service;
  Future<void> Function(dynamic item)? _resolverConfigurator;
  final QueueService queueService = QueueService();
  final PlayerState state = PlayerState();
  final List<StreamSubscription> _streamSubs = [];
  Timer? _progressTimer;
  StreamResolutionResult? _currentResolution;
  int? _audioStreamIndex;
  int? _subtitleStreamIndex;
  String? _mediaSourceId;
  Duration _lastKnownPosition = Duration.zero;
  Duration _transcodeStartOffset = Duration.zero;
  Duration _itemKnownDuration = Duration.zero;
  int? _maxBitrateOverrideMbps;
  DateTime? _playbackStartTime;
  bool _waitingForMedia = false;
  bool _isAutoNexting = false;
  bool _isManualNexting = false;
  bool suppressAutoNext = false;
  bool _isOfflinePlayback = false;
  Future<void> Function()? _onOfflineStop;
  Future<void> Function(String url)? _onOfflineAutoNext;
  Map<String, Map<String, dynamic>> _offlineMetadataByUrl = {};
  Future<void>? _stopInFlight;
  int _playbackSessionToken = 0;

  PlayerBackend? get backend => _backend;
  StreamResolutionResult? get currentResolution => _currentResolution;
  int? get audioStreamIndex => _audioStreamIndex;
  int? get subtitleStreamIndex => _subtitleStreamIndex;
  int? get maxBitrateOverrideMbps => _maxBitrateOverrideMbps;
  bool get isOfflinePlayback => _isOfflinePlayback;
  Map<String, dynamic>? get currentOfflineMetadata {
    final url = queueService.currentItem;
    if (url is! String) return null;
    return _offlineMetadataByUrl[url];
  }

  void setOfflineMetadataByUrl(Map<String, Map<String, dynamic>> metadata) {
    _offlineMetadataByUrl = metadata;
  }

  List<Map<String, dynamic>> get _currentMediaStreams {
    final resStreams = _currentResolution?.mediaStreams;
    if (resStreams != null) return resStreams;
    final url = queueService.currentItem;
    if (url is! String) return const [];
    final meta = _offlineMetadataByUrl[url];
    return (meta?['MediaStreams'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  }

  void setBackend(PlayerBackend backend) {
    _disposeStreamSubs();
    _backend?.dispose();
    _backend = backend;
    _bindStreams(backend);
  }

  void setResolver(MediaStreamResolver resolver) {
    _resolver = resolver;
  }

  void setPlayerService(PlayerService service) {
    _service = service;
  }

  void setResolverConfigurator(Future<void> Function(dynamic item) configurator) {
    _resolverConfigurator = configurator;
  }

  void _bindStreams(PlayerBackend backend) {
    _streamSubs.addAll([
      backend.positionStream.listen((pos) {
        final adjusted = pos + _transcodeStartOffset;
        state.setPosition(adjusted);
        if (adjusted > Duration.zero) _lastKnownPosition = adjusted;
      }),
      backend.durationStream.listen((dur) {
        if (_itemKnownDuration > Duration.zero &&
            dur.inMilliseconds < _itemKnownDuration.inMilliseconds * 9 ~/ 10) {
          state.setDuration(_itemKnownDuration);
        } else {
          state.setDuration(dur);
        }
      }),
      backend.playingStream.listen(state.setPlaying),
      backend.bufferingStream.listen(state.setBuffering),
      backend.completedStream.listen(_onTrackCompleted),
    ]);
  }

  void _disposeStreamSubs() {
    for (final sub in _streamSubs) {
      sub.cancel();
    }
    _streamSubs.clear();
  }

  Duration _resolvedItemDuration(dynamic item, String? mediaSourceId) {
    if (mediaSourceId != null) {
      try {
        final mediaSources = item.mediaSources as List?;
        if (mediaSources != null) {
          for (final source in mediaSources) {
            if (source is! Map) continue;
            if (source['Id'] != mediaSourceId) continue;
            final ticks = source['RunTimeTicks'];
            if (ticks is int && ticks > 0) {
              return Duration(microseconds: ticks ~/ 10);
            }
            if (ticks is num && ticks > 0) {
              return Duration(microseconds: ticks.toInt() ~/ 10);
            }
            break;
          }
        }
      } catch (_) {}
    }

    try {
      final runtime = item.runtime as Duration?;
      if (runtime != null) {
        return runtime;
      }
    } catch (_) {}

    return Duration.zero;
  }

  void _onTrackCompleted(bool completed) {
    if (!completed) return;
    if (_waitingForMedia || _isAutoNexting || _isManualNexting || suppressAutoNext) return;
    // Ignore completed events that fire during initial load/seek.
    if (_playbackStartTime != null &&
        DateTime.now().difference(_playbackStartTime!).inSeconds < 5) {
      return;
    }
    final pos = _lastKnownPosition > state.position
        ? _lastKnownPosition
        : state.position;
    final backendDuration = _backend?.duration ?? Duration.zero;
    final effectiveDuration = _itemKnownDuration > Duration.zero
        ? _itemKnownDuration
        : (backendDuration > Duration.zero ? backendDuration : state.duration);

    if (effectiveDuration <= Duration.zero) {
      return;
    }

    final remaining = effectiveDuration - pos;
    if (remaining > const Duration(seconds: 5)) {
      return;
    }

    _isAutoNexting = true;
    _autoNext().whenComplete(() => _isAutoNexting = false);
  }

  Future<void> _autoNext() async {
    _mediaSourceId = null;
    if (_isOfflinePlayback) {
      await _stopAndReportCurrent(skipQueueChange: true);
      final hadNext = queueService.next();
      if (hadNext) {
        final item = queueService.currentItem as String?;
        if (item != null) await _onOfflineAutoNext?.call(item);
      }
      return;
    }
    await _stopAndReportCurrent(skipQueueChange: true);
    final hadNext = queueService.next();
    if (hadNext) {
      await _playCurrentItem();
    }
  }

  Future<void> playItems(
    List<dynamic> items, {
    int startIndex = 0,
    Duration startPosition = Duration.zero,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
    String? mediaSourceId,
  }) async {
    _isAutoNexting = false;
    _isManualNexting = false;
    suppressAutoNext = false;
    await _stopAndReportCurrent();
    _audioStreamIndex = audioStreamIndex;
    _subtitleStreamIndex = subtitleStreamIndex;
    _mediaSourceId = mediaSourceId;
    queueService.setQueue(items, startIndex: startIndex);
    await _playCurrentItem(startPosition: startPosition);
  }

  Future<void> _playCurrentItem({
    Duration startPosition = Duration.zero,
    bool enableDirectPlay = true,
    bool enableDirectStream = true,
  }) async {
    final item = queueService.currentItem;
    if (item == null || _backend == null) {
      return;
    }

    _lastKnownPosition = Duration.zero;
    final sessionToken = ++_playbackSessionToken;

    if (_resolverConfigurator != null) {
      await _resolverConfigurator!(item);
    }

    if (_resolver == null) {
      throw StateError('No MediaStreamResolver configured');
    }

    final startTicks =
        startPosition > Duration.zero ? startPosition.inMicroseconds * 10 : null;

    final forceTranscode = !enableDirectPlay && !enableDirectStream;
    final profile = _backend!.getDeviceProfile(
      useProgressiveTranscode: forceTranscode,
    );
    if (_maxBitrateOverrideMbps != null) {
      profile['MaxStreamingBitrate'] = _maxBitrateOverrideMbps! * 1000000;
    }
    final maxBitrate = profile['MaxStreamingBitrate'] as int?;

    final resolution = await _resolver!.resolve(
      item,
      deviceProfile: profile,
      maxStreamingBitrate: maxBitrate,
      audioStreamIndex: _audioStreamIndex,
      subtitleStreamIndex: _subtitleStreamIndex,
      startTimeTicks: startTicks,
      mediaSourceId: _mediaSourceId,
      enableDirectPlay: enableDirectPlay,
      enableDirectStream: enableDirectStream,
    );
    _currentResolution = resolution;
    _mediaSourceId = resolution.mediaSourceId;
    _itemKnownDuration = _resolvedItemDuration(item, resolution.mediaSourceId);

    if (resolution.playMethod == StreamPlayMethod.transcode &&
        startPosition > Duration.zero) {
      _transcodeStartOffset = startPosition;
    } else {
      _transcodeStartOffset = Duration.zero;
    }

    if (_itemKnownDuration > Duration.zero) {
      state.setDuration(_itemKnownDuration);
    }

    _playbackStartTime = DateTime.now();
    _waitingForMedia = true;
    await _backend!.play(resolution.streamUrl);

    await _waitForMediaReady(
      isTranscode: resolution.playMethod == StreamPlayMethod.transcode,
    );
    _waitingForMedia = false;

    if (startTicks != null && resolution.playMethod != StreamPlayMethod.transcode) {
      try {
        await _backend!.seekTo(startPosition);

        for (var i = 0; i < 30; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
          final pos = _backend!.position;
          if ((pos - startPosition).abs() < const Duration(seconds: 10)) {
            break;
          }
        }
      } catch (_) {}
    }

    for (final sub in resolution.externalSubtitles) {
      await _backend!.addExternalSubtitle(
        sub.deliveryUrl,
        title: sub.title,
        language: sub.language,
      );
    }

    if (resolution.playMethod == StreamPlayMethod.directPlay) {
      if (_audioStreamIndex != null || (_subtitleStreamIndex != null && _subtitleStreamIndex != -1)) {
        _waitAndApplyTrackSelections(sessionToken);
      } else if (_subtitleStreamIndex == -1) {
        _waitAndDisableSubtitles(sessionToken);
      }
    } else if (resolution.playMethod == StreamPlayMethod.transcode) {
      if (_subtitleStreamIndex != null && _subtitleStreamIndex != -1) {
        final isBurnedIn = _isSubtitleBitmap(_subtitleStreamIndex!) &&
            !(_backend?.canRenderBitmapSubtitles ?? false);
        if (!isBurnedIn) {
          _waitAndApplyExternalSubtitle(sessionToken, resolution);
        }
      } else if (_subtitleStreamIndex == -1) {
        _waitAndDisableSubtitles(sessionToken);
      }
    }

    _service?.onPlaybackStart(
      item,
      resolution,
      positionTicks: startTicks,
      audioStreamIndex: _audioStreamIndex,
      subtitleStreamIndex: _subtitleStreamIndex,
    );
    _startProgressTimer();
  }

  void _startProgressTimer() {
    _stopProgressTimer();
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final item = queueService.currentItem;
      final resolution = _currentResolution;
      if (item == null || resolution == null) return;
      _service?.onPlaybackProgress(
        item,
        resolution,
        state.position,
        isPaused: !state.isPlaying,
        audioStreamIndex: _audioStreamIndex,
        subtitleStreamIndex: _subtitleStreamIndex,
      );
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  Future<void> resume() async {
    await _backend?.resume();
  }

  Future<void> pause() async {
    await _backend?.pause();
  }

  /// Polls until the backend reports a non-zero duration, indicating the
  /// media is ready for seeking / track selection. For transcoded streams,
  /// also accepts [isPlaying] since the full duration may never arrive.
  Future<void> _waitForMediaReady({bool isTranscode = false}) async {
    bool isReady() {
      if (_backend!.duration > Duration.zero) return true;
      if (isTranscode && _backend!.isPlaying) return true;
      return false;
    }

    if (isReady()) return;

    for (var i = 0; i < 600; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (isReady()) return;
    }
  }

  Future<void> stop() async {
    await _stopAndReportCurrent();
  }

  Future<void> seekTo(Duration position) async {
    _lastKnownPosition = position;
    await _backend?.seekTo(position);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _backend?.setPlaybackSpeed(speed);
    state.setPlaybackSpeed(speed);
  }

  Future<void> next() async {
    if (_isManualNexting || _isAutoNexting) return;
    _isManualNexting = true;
    _mediaSourceId = null;
    try {
      await _stopAndReportCurrent(skipQueueChange: true);
      final hadNext = queueService.next();
      if (hadNext) {
        await _playCurrentItem();
      }
    } finally {
      _isManualNexting = false;
    }
  }

  Future<void> previous() async {
    if (state.position.inSeconds > 3) {
      await seekTo(Duration.zero);
      return;
    }
    _mediaSourceId = null;
    await _stopAndReportCurrent(skipQueueChange: true);
    final hadPrevious = queueService.previous();
    if (hadPrevious) {
      await _playCurrentItem();
    }
  }

  Future<void> playFromQueue(int index) async {
    _mediaSourceId = null;
    await _stopAndReportCurrent(skipQueueChange: true);
    queueService.jumpTo(index);
    await _playCurrentItem();
  }

  void toggleRepeat() {
    queueService.toggleRepeat();
    state.setRepeatMode(queueService.repeatMode);
  }

  void toggleShuffle() {
    queueService.toggleShuffle();
    state.setShuffled(queueService.isShuffled);
  }

  Future<void> changeAudioTrack(int streamIndex) async {
    _audioStreamIndex = streamIndex;

    if (_currentResolution?.playMethod == StreamPlayMethod.directPlay || _isOfflinePlayback) {
      final mpvId = _mpvTrackIdForStream(streamIndex, 'Audio');
      if (mpvId != null) {
        await _backend?.setAudioTrack(mpvId);
      }
    } else {
      await _reResolveAtCurrentPosition();
    }
  }

  static const _bitmapSubCodecs = {'pgs', 'pgssub', 'dvbsub', 'dvdsub', 'hdmv_pgs_subtitle', 'dvd_subtitle', 'dvb_subtitle', 'xsub'};

  bool _isSubtitleBitmap(int streamIndex) {
    final streams = _currentMediaStreams;
    if (streams.isEmpty) return false;
    final sub = streams.where((s) => s['Type'] == 'Subtitle').firstWhere(
      (s) => s['Index'] == streamIndex,
      orElse: () => <String, dynamic>{},
    );
    final codec = ((sub['Codec'] as String?) ?? '').toLowerCase();
    return _bitmapSubCodecs.contains(codec);
  }

  Future<void> changeSubtitleTrack(int streamIndex) async {
    final isBitmap = _isSubtitleBitmap(streamIndex);
    _subtitleStreamIndex = streamIndex;

    if (_currentResolution?.playMethod == StreamPlayMethod.directPlay || _isOfflinePlayback) {
      if (isBitmap && !(_backend?.canRenderBitmapSubtitles ?? false)) {
        await _backend?.disableSubtitleTrack();
        if (!_isOfflinePlayback) {
          await _reResolveAtCurrentPosition(forceTranscode: true);
        }
        return;
      }
      final mpvId = _mpvTrackIdForStream(streamIndex, 'Subtitle');
      if (mpvId != null) {
        await _backend?.setSubtitleTrack(mpvId, isBitmapSubtitle: isBitmap);
      }
    } else if (_currentResolution?.playMethod == StreamPlayMethod.transcode) {
      // For transcoded streams, select the matching external subtitle track.
      final externalSubs = _currentResolution!.externalSubtitles;
      final idx = externalSubs.indexWhere((s) => s.streamIndex == streamIndex);
      if (idx >= 0) {
        final mpvId = idx + 1;
        await _backend?.setSubtitleTrack(mpvId);
      } else {
        await _reResolveAtCurrentPosition(forceTranscode: true);
      }
    } else {
      await _reResolveAtCurrentPosition();
    }
  }

  Future<void> disableSubtitles() async {
    _subtitleStreamIndex = -1;
    await _backend?.disableSubtitleTrack();
  }

  /// Change the transcode bitrate and re-resolve the stream.
  Future<void> changeBitrate(int? mbps) async {
    _maxBitrateOverrideMbps = mbps;
    final isTranscode = _currentResolution?.playMethod == StreamPlayMethod.transcode;
    if (isTranscode) {
      await _reResolveAtCurrentPosition(forceTranscode: true);
    }
  }

  Future<void> _reResolveAtCurrentPosition({bool forceTranscode = false}) async {
    final rawBackendPos = _backend?.position ?? Duration.zero;
    final backendPos = rawBackendPos + _transcodeStartOffset;
    final statePos = state.position;
    final currentPos = backendPos > Duration.zero
        ? backendPos
        : (statePos > Duration.zero ? statePos : _lastKnownPosition);
    _stopProgressTimer();
    final item = queueService.currentItem;
    final resolution = _currentResolution;
    if (item != null && resolution != null) {
      _service?.onPlaybackStop(item, resolution, currentPos);
    }
    _currentResolution = null;
    await _backend?.stop();
    await _playCurrentItem(
      startPosition: currentPos,
      enableDirectPlay: !forceTranscode,
      enableDirectStream: !forceTranscode,
    );
  }

  Future<void> _applyStoredTrackSelections(int sessionToken) async {
    if (sessionToken != _playbackSessionToken) return;
    if (_audioStreamIndex != null) {
      final mpvId = _mpvTrackIdForStream(_audioStreamIndex!, 'Audio');
      if (mpvId != null && mpvId > 1) {
        await _backend?.setAudioTrack(mpvId);
        if (sessionToken != _playbackSessionToken) return;
      }
    }
    if (_subtitleStreamIndex != null && _subtitleStreamIndex! >= 0) {
      final isBitmap = _isSubtitleBitmap(_subtitleStreamIndex!);
      if (!(isBitmap && !(_backend?.canRenderBitmapSubtitles ?? false))) {
        final mpvId = _mpvTrackIdForStream(_subtitleStreamIndex!, 'Subtitle');
        if (mpvId != null) {
          await _backend?.setSubtitleTrack(mpvId, isBitmapSubtitle: isBitmap);
          if (sessionToken != _playbackSessionToken) return;
        }
      }
    } else if (_subtitleStreamIndex == -1) {
      await _backend?.disableSubtitleTrack();
    }
  }

  void _waitAndApplyTrackSelections(int sessionToken) {
    _backend?.waitForTracksReady().then((_) {
      if (sessionToken != _playbackSessionToken) return;
      _applyStoredTrackSelections(sessionToken);
    });
  }

  void _waitAndDisableSubtitles(int sessionToken) {
    _backend?.waitForTracksReady().then((_) {
      if (sessionToken != _playbackSessionToken) return;
      _backend?.disableSubtitleTrack();
    });
  }

  void _waitAndApplyExternalSubtitle(
    int sessionToken,
    StreamResolutionResult resolution,
  ) {
    _backend?.waitForTracksReady().then((_) async {
      if (sessionToken != _playbackSessionToken) return;
      if (_subtitleStreamIndex == null || _subtitleStreamIndex! < 0) return;
      final externalSubs = resolution.externalSubtitles;
      final idx = externalSubs.indexWhere(
        (s) => s.streamIndex == _subtitleStreamIndex,
      );
      if (idx >= 0) {
        final mpvId = idx + 1;
        await _backend?.setSubtitleTrack(mpvId);
      }
    });
  }

  /// Maps a Jellyfin stream Index to an mpv track ID (1-indexed among same-type tracks).
  int? _mpvTrackIdForStream(int streamIndex, String type) {
    final streams = _currentMediaStreams;
    if (streams.isEmpty) {
      return null;
    }
    final typeStreams = streams.where((s) => s['Type'] == type).toList();
    if (typeStreams.isEmpty) {
      return null;
    }

    if (type == 'Subtitle') {
      final targetIdx = typeStreams.indexWhere((s) => s['Index'] == streamIndex);
      if (targetIdx < 0) {
        return null;
      }
      final target = typeStreams[targetIdx];
      final isExternal = target['IsExternal'] == true;

      if (isExternal) {
        final embeddedCount = typeStreams.where((s) => s['IsExternal'] != true).length;
        final externalStreams = typeStreams.where((s) => s['IsExternal'] == true).toList();
        final externalPos = externalStreams.indexWhere((s) => s['Index'] == streamIndex);
        if (externalPos < 0) return null;
        final mpvId = embeddedCount + externalPos + 1;
        return mpvId;
      } else {
        final embeddedStreams = typeStreams.where((s) => s['IsExternal'] != true).toList();
        final embeddedPos = embeddedStreams.indexWhere((s) => s['Index'] == streamIndex);
        if (embeddedPos < 0) return null;
        final mpvId = embeddedPos + 1;
        return mpvId;
      }
    }

    final positional = typeStreams.indexWhere((s) => s['Index'] == streamIndex);
    if (positional < 0) {
      return null;
    }
    final mpvId = positional + 1;
    return mpvId;
  }

  Future<void> playOffline(
    String url, {
    Duration startPosition = Duration.zero,
    Duration itemDuration = Duration.zero,
    List<String> queueUrls = const [],
    int startIndex = 0,
    Future<void> Function()? onStop,
    Future<void> Function(String url)? onAutoNext,
  }) async {
    _isAutoNexting = false;
    _isManualNexting = false;
    suppressAutoNext = false;
    await _stopAndReportCurrent();
    _isOfflinePlayback = true;
    _onOfflineStop = onStop;
    _onOfflineAutoNext = onAutoNext;
    _itemKnownDuration = itemDuration;
    _transcodeStartOffset = Duration.zero;
    _currentResolution = null;

    if (queueUrls.isNotEmpty) {
      queueService.setQueue(queueUrls, startIndex: startIndex);
    } else {
      queueService.setQueue([url]);
    }

    if (itemDuration > Duration.zero) {
      state.setDuration(itemDuration);
    }

    _playbackStartTime = DateTime.now();
    _waitingForMedia = true;
    await _backend!.play(url);
    await _waitForMediaReady();
    _waitingForMedia = false;

    if (startPosition > Duration.zero) {
      try {
        await _backend!.seekTo(startPosition);
      } catch (_) {}
    }
  }

  Future<void> _stopAndReportCurrent({bool skipQueueChange = false}) async {
    final existingStop = _stopInFlight;
    if (existingStop != null) {
      await existingStop;
      return;
    }

    final stopFuture = (() async {
      _playbackSessionToken++;
      _stopProgressTimer();
      if (_isOfflinePlayback) {
        await _backend?.stop();
        if (!skipQueueChange) {
          await _onOfflineStop?.call();
          _isOfflinePlayback = false;
          _onOfflineStop = null;
          _onOfflineAutoNext = null;
          queueService.clear();
          state.reset();
        }
        return;
      }
      final item = queueService.currentItem;
      final resolution = _currentResolution;
      if (item != null && resolution != null) {
        final pos = state.position > Duration.zero
            ? state.position
            : _lastKnownPosition;
        try {
          await _service?.onPlaybackStop(item, resolution, pos);
        } catch (_) {}
      }
      _currentResolution = null;
      await _backend?.stop();
      if (!skipQueueChange) {
        queueService.clear();
        state.reset();
      }
    })();

    _stopInFlight = stopFuture;
    try {
      await stopFuture;
    } finally {
      if (identical(_stopInFlight, stopFuture)) {
        _stopInFlight = null;
      }
    }
  }

  void dispose() {
    _stopProgressTimer();
    _disposeStreamSubs();
    _backend?.dispose();
    _service?.dispose();
    queueService.dispose();
    state.dispose();
  }
}
