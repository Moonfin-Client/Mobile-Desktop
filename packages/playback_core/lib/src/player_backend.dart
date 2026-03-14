abstract class PlayerBackend {
  Future<void> play(dynamic mediaItem);
  Future<void> resume();
  Future<void> pause();
  Future<void> stop();
  Future<void> seekTo(Duration position);

  Duration get position;
  Duration get duration;
  bool get isPlaying;
  bool get isBuffering;
  double get playbackSpeed;

  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  Stream<bool> get playingStream;
  Stream<bool> get bufferingStream;
  Stream<bool> get completedStream;

  Map<String, dynamic> getDeviceProfile({bool useProgressiveTranscode = false});

  Future<void> setPlaybackSpeed(double speed);
  Future<void> setAudioTrack(int index);
  Future<void> setSubtitleTrack(int index, {bool isBitmapSubtitle = false});
  Future<void> disableSubtitleTrack();
  Future<void> waitForTracksReady();
  Future<void> setVolume(double volume);
  Future<void> setAudioDelay(double seconds);
  Future<void> setSubtitleDelay(double seconds);
  Future<void> addExternalSubtitle(String url, {String? title, String? language});
  Future<void> configureSubtitleStyle({
    int? textColor,
    int? backgroundColor,
    int? strokeColor,
    double? fontSize,
    int? fontWeight,
    double? verticalOffset,
  });

  bool get canRenderBitmapSubtitles;

  void dispose();
}
