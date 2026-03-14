import 'dart:async';

import 'queue_service.dart';

class PlayerState {
  final _playingController = StreamController<bool>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _bufferingController = StreamController<bool>.broadcast();
  final _repeatModeController = StreamController<RepeatMode>.broadcast();
  final _shuffleController = StreamController<bool>.broadcast();

  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  RepeatMode _repeatMode = RepeatMode.none;
  bool _isShuffled = false;

  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  Duration get position => _position;
  Duration get duration => _duration;
  double get playbackSpeed => _playbackSpeed;
  RepeatMode get repeatMode => _repeatMode;
  bool get isShuffled => _isShuffled;

  Stream<bool> get playingStream => _playingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<bool> get bufferingStream => _bufferingController.stream;
  Stream<RepeatMode> get repeatModeStream => _repeatModeController.stream;
  Stream<bool> get shuffleStream => _shuffleController.stream;

  void setPlaying(bool playing) {
    _isPlaying = playing;
    _playingController.add(playing);
  }

  void setBuffering(bool buffering) {
    _isBuffering = buffering;
    _bufferingController.add(buffering);
  }

  void setPosition(Duration position) {
    _position = position;
    _positionController.add(position);
  }

  void setDuration(Duration duration) {
    _duration = duration;
    _durationController.add(duration);
  }

  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed;
  }

  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
    _repeatModeController.add(mode);
  }

  void setShuffled(bool shuffled) {
    _isShuffled = shuffled;
    _shuffleController.add(shuffled);
  }

  void reset() {
    _isPlaying = false;
    _isBuffering = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _playbackSpeed = 1.0;
    _playingController.add(false);
    _bufferingController.add(false);
    _positionController.add(Duration.zero);
    _durationController.add(Duration.zero);
  }

  void dispose() {
    _playingController.close();
    _positionController.close();
    _durationController.close();
    _bufferingController.close();
    _repeatModeController.close();
    _shuffleController.close();
  }
}
