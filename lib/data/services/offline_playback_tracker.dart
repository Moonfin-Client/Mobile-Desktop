import 'dart:async';

import '../repositories/offline_repository.dart';

class OfflinePlaybackTracker {
  final OfflineRepository _repo;
  Timer? _progressTimer;
  StreamSubscription<Duration>? _positionSub;
  String? _activeItemId;
  String? _activeServerId;
  Duration _lastPosition = Duration.zero;
  Duration _itemDuration = Duration.zero;
  bool _markedComplete = false;

  OfflinePlaybackTracker(this._repo);

  void startTracking({
    required String itemId,
    required String serverId,
    required Duration duration,
    required Stream<Duration> positionStream,
  }) {
    stopTracking();
    _activeItemId = itemId;
    _activeServerId = serverId;
    _itemDuration = duration;
    _markedComplete = false;

    _positionSub = positionStream.listen((pos) => _lastPosition = pos);

    _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _saveProgress();
    });
  }

  Future<void> _saveProgress() async {
    if (_activeItemId == null || _activeServerId == null) return;
    if (_lastPosition <= Duration.zero) return;

    if (!_markedComplete &&
        _itemDuration > Duration.zero &&
        _lastPosition.inMilliseconds / _itemDuration.inMilliseconds > 0.9) {
      _markedComplete = true;
      await _repo.updatePlaybackPosition(_activeItemId!, _activeServerId!, 0);
      return;
    }

    if (!_markedComplete) {
      final ticks = _lastPosition.inMicroseconds * 10;
      await _repo.updatePlaybackPosition(_activeItemId!, _activeServerId!, ticks);
    }
  }

  Future<void> stopTracking() async {
    _progressTimer?.cancel();
    _progressTimer = null;
    _positionSub?.cancel();
    _positionSub = null;
    await _saveProgress();
    _activeItemId = null;
    _activeServerId = null;
    _lastPosition = Duration.zero;
    _itemDuration = Duration.zero;
    _markedComplete = false;
  }
}
