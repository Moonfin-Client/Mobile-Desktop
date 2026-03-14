import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:playback_core/playback_core.dart';

import '../preference/user_preferences.dart';
import '../preference/preference_constants.dart';
import '../util/platform_detection.dart';
import 'device_profile_builder.dart';

class MediaKitPlayerBackend implements PlayerBackend {
  final Player _player;
  final VideoController _videoController;
  final UserPreferences _prefs;

  static bool get _useLibass => PlatformDetection.isDesktop;

  MediaKitPlayerBackend._(this._player, this._videoController, this._prefs);

  factory MediaKitPlayerBackend(UserPreferences prefs) {
    final player = Player(
      configuration: PlayerConfiguration(
        libass: _useLibass,
      ),
    );
    final platform = player.platform;
    if (platform is NativePlayer) {
      platform.setProperty('network-timeout', '60');
    }
    final controller = VideoController(player);
    return MediaKitPlayerBackend._(player, controller, prefs);
  }

  @override
  bool get canRenderBitmapSubtitles => _useLibass;

  VideoController get videoController => _videoController;

  @override
  Map<String, dynamic> getDeviceProfile({bool useProgressiveTranscode = false}) {
    final maxBitrate = int.tryParse(_prefs.get(UserPreferences.maxBitrate));
    final ac3Enabled = _prefs.get(UserPreferences.ac3Enabled);
    final stereoDownmix =
        _prefs.get(UserPreferences.audioBehavior) == AudioBehavior.downmixToStereo;

    return DeviceProfileBuilder.build(
      maxBitrateMbps: maxBitrate,
      ac3Enabled: ac3Enabled,
      stereoDownmix: stereoDownmix,
      useProgressiveTranscode: useProgressiveTranscode,
    );
  }

  @override
  Future<void> play(dynamic mediaItem) async {
    final url = mediaItem as String;
    _player.open(Media(url));
    if (!_useLibass) {
      _enableNativeSubtitleRendering();
    }
  }

  @override
  Future<void> resume() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  @override
  Duration get position => _player.state.position;

  @override
  Duration get duration => _player.state.duration;

  @override
  bool get isPlaying => _player.state.playing;

  @override
  bool get isBuffering => _player.state.buffering;

  @override
  double get playbackSpeed => _player.state.rate;

  @override
  Stream<Duration> get positionStream => _player.stream.position;

  @override
  Stream<Duration> get durationStream => _player.stream.duration;

  @override
  Stream<bool> get playingStream => _player.stream.playing;

  @override
  Stream<bool> get bufferingStream => _player.stream.buffering;

  @override
  Stream<bool> get completedStream => _player.stream.completed;

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    await _player.setRate(speed);
  }

  @override
  Future<void> setAudioTrack(int mpvTrackId) async {
    if (mpvTrackId < 1) return;
    final id = mpvTrackId.toString();
    try {
      final tracks = _player.state.tracks.audio;
      AudioTrack? match;
      for (final t in tracks) {
        if (t.id == id) { match = t; break; }
      }
      print('MOONFIN: setAudioTrack aid=$id match=${match != null} available=[${tracks.map((t) => "${t.id}:${t.title}").join(", ")}]');
      if (match != null) {
        await _player.setAudioTrack(match);
      } else {
        await _player.setAudioTrack(AudioTrack(id, null, null));
      }
    } catch (e) {
      print('MOONFIN: setAudioTrack ERROR aid=$id: $e');
      try {
        final native = _player.platform as NativePlayer;
        await native.setProperty('aid', id);
      } catch (_) {}
    }
  }

  @override
  Future<void> setSubtitleTrack(int mpvTrackId, {bool isBitmapSubtitle = false}) async {
    if (mpvTrackId < 1) return;
    final id = mpvTrackId.toString();
    try {
      await _player.setSubtitleTrack(SubtitleTrack.no());

      final tracks = _player.state.tracks.subtitle;
      SubtitleTrack? match;
      for (final t in tracks) {
        if (t.id == id) { match = t; break; }
      }
      print('MOONFIN: setSubtitleTrack sid=$id match=${match != null} bitmap=$isBitmapSubtitle libass=$_useLibass available=[${tracks.map((t) => "${t.id}:${t.title}:${t.language}").join(", ")}]');

      if (match != null) {
        await _player.setSubtitleTrack(match);
      } else {
        await _player.setSubtitleTrack(SubtitleTrack(id, null, null));
      }

      final native = _player.platform as NativePlayer;
      if (!_useLibass) {
        await native.setProperty('sub-visibility', 'no');
      }

      final currentSid = await native.getProperty('sid');
      final subVis = await native.getProperty('sub-visibility');
      print('MOONFIN: setSubtitleTrack confirmed=$currentSid vis=$subVis');
    } catch (e) {
      print('MOONFIN: setSubtitleTrack ERROR sid=$id: $e');
    }
  }

  @override
  Future<void> disableSubtitleTrack() async {
    await _player.setSubtitleTrack(SubtitleTrack.no());
  }

  @override
  Future<void> waitForTracksReady() async {
    if (_player.state.tracks.audio.isNotEmpty) {
      print('MOONFIN: waitForTracksReady: already available (${_player.state.tracks.audio.length} audio, ${_player.state.tracks.subtitle.length} sub)');
      return;
    }
    try {
      await _player.stream.tracks
          .firstWhere((t) => t.audio.isNotEmpty)
          .timeout(const Duration(seconds: 5));
      print('MOONFIN: waitForTracksReady: tracks became available');
    } catch (_) {
      print('MOONFIN: waitForTracksReady: timed out');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0, 100));
  }

  @override
  Future<void> setAudioDelay(double seconds) async {
    final native = _player.platform as NativePlayer;
    await native.setProperty('audio-delay', seconds.toStringAsFixed(3));
  }

  @override
  Future<void> setSubtitleDelay(double seconds) async {
    final native = _player.platform as NativePlayer;
    await native.setProperty('sub-delay', seconds.toStringAsFixed(3));
  }

  @override
  Future<void> addExternalSubtitle(
    String url, {
    String? title,
    String? language,
  }) async {
    print('MOONFIN: sub-add url=$url title=$title');
    final native = _player.platform as NativePlayer;
    await native.command([
      'sub-add',
      url,
      'auto',
      title ?? 'external',
      language ?? '',
    ]);
  }

  @override
  Future<void> configureSubtitleStyle({
    int? textColor,
    int? backgroundColor,
    int? strokeColor,
    double? fontSize,
    int? fontWeight,
    double? verticalOffset,
  }) async {
    try {
      final native = _player.platform as NativePlayer;
      if (textColor != null) {
        await native.setProperty('sub-color', _argbToMpvColor(textColor));
      }
      if (backgroundColor != null) {
        await native.setProperty(
            'sub-back-color', _argbToMpvColor(backgroundColor));
      }
      if (strokeColor != null) {
        await native.setProperty(
            'sub-border-color', _argbToMpvColor(strokeColor));
        await native.setProperty('sub-border-size', '2');
      }
      if (fontSize != null) {
        final mpvSize = ((fontSize / 24.0) * 55.0).round().clamp(24, 120);
        await native.setProperty('sub-font-size', mpvSize.toString());
      }
      if (fontWeight != null && fontWeight >= 700) {
        await native.setProperty('sub-bold', 'yes');
      }
      if (verticalOffset != null) {
        final marginY = (verticalOffset * 720).round();
        await native.setProperty('sub-margin-y', marginY.toString());
      }
    } catch (e) {
      print('MOONFIN: configureSubtitleStyle ERROR: $e');
    }
  }

  void _enableNativeSubtitleRendering() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        final native = _player.platform as NativePlayer;
        await native.setProperty('sub-visibility', 'no');
        await native.setProperty('sub-ass', 'yes');
        await native.setProperty('sub-ass-override', 'yes');
        await native.setProperty('sub-forced-events-only', 'no');
      } catch (e) {
        print('MOONFIN: _enableNativeSubtitleRendering ERROR: $e');
      }
    });
  }

  static String _argbToMpvColor(int argb) {
    final a = (argb >> 24) & 0xFF;
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}'
        '${a.toRadixString(16).padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _player.dispose();
  }
}
