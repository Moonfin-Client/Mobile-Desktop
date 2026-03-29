import 'dart:io';

import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:playback_core/playback_core.dart';

import '../preference/user_preferences.dart';
import '../preference/preference_constants.dart';
import '../util/platform_detection.dart';
import 'device_profile_builder.dart';

class MediaKitPlayerBackend implements PlayerBackend {
  final Player _player;
  final VideoController _videoController;
  final UserPreferences _prefs;
  final Future<void> Function(int handle)? _onNativeHandleReady;
  bool _didNotifyNativeHandle = false;
  bool _didConfigureAppleMobileLibassFont = false;

  static bool get _useLibass =>
      PlatformDetection.isDesktop || Platform.isAndroid || Platform.isIOS;

  MediaKitPlayerBackend._(
    this._player,
    this._videoController,
    this._prefs,
    this._onNativeHandleReady,
  );

  factory MediaKitPlayerBackend(
    UserPreferences prefs, {
    Future<void> Function(int handle)? onNativeHandleReady,
  }) {
    final player = Player(
      configuration: PlayerConfiguration(
        libass: _useLibass,
        libassAndroidFont: Platform.isAndroid
            ? 'assets/fonts/NotoSans-Regular.ttf'
            : null,
        libassAndroidFontName: Platform.isAndroid ? 'Noto Sans' : null,
      ),
    );
    final platform = player.platform;
    if (platform is NativePlayer) {
      platform.setProperty('network-timeout', '120');
    }
    final controller = VideoController(
      player,
      configuration: VideoControllerConfiguration(
        hwdec: PlatformDetection.isLinux && !PlatformDetection.isLinuxWayland
            ? 'no'
            : null,
      ),
    );
    return MediaKitPlayerBackend._(
      player,
      controller,
      prefs,
      onNativeHandleReady,
    );
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
    await _notifyNativeHandleReady();
    await _configureAppleMobileLibassFont();
    await _applyAssOverrideMode();
    _player.open(Media(url));
    if (!_useLibass) {
      _enableNativeSubtitleRendering();
    }
  }

  Future<void> _configureAppleMobileLibassFont() async {
    if (!Platform.isIOS || _didConfigureAppleMobileLibassFont) {
      return;
    }
    try {
      final supportDirectory = await getApplicationSupportDirectory();
      final fontsDirectory =
          Directory('${supportDirectory.path}/moonfin-subfonts');
      await fontsDirectory.create(recursive: true);

      final fontFile = File('${fontsDirectory.path}/NotoSans-Regular.ttf');
      if (!await fontFile.exists()) {
        final data = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
        await fontFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }

      final native = _player.platform as NativePlayer;
      await native.setProperty('sub-fonts-dir', fontsDirectory.path);
      await native.setProperty('sub-font', 'Noto Sans');
      await native.setProperty('sub-ass', 'yes');
      await native.setProperty('sub-visibility', 'yes');
      _didConfigureAppleMobileLibassFont = true;
    } catch (_) {}
  }

  Future<void> _applyAssOverrideMode() async {
    if (!_useLibass) {
      return;
    }
    try {
      final native = _player.platform as NativePlayer;
      final assEnabled = _prefs.get(UserPreferences.assDirectPlay);
      await native.setProperty('sub-ass-override', assEnabled ? 'no' : 'force');
    } catch (_) {}
  }

  Future<void> _notifyNativeHandleReady() async {
    final onNativeHandleReady = _onNativeHandleReady;
    if (_didNotifyNativeHandle || onNativeHandleReady == null) {
      return;
    }
    if (_player.platform is! NativePlayer) {
      return;
    }
    try {
      final handle = await _player.handle;
      await onNativeHandleReady(handle);
      _didNotifyNativeHandle = true;
    } catch (_) {}
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

  Future<void> setVideoEnabled(bool enabled) async {
    try {
      final native = _player.platform as NativePlayer;
      await native.setProperty('vid', enabled ? 'auto' : 'no');
    } catch (_) {}
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
      if (match != null) {
        await _player.setAudioTrack(match);
      } else {
        await _player.setAudioTrack(AudioTrack(id, null, null));
      }
    } catch (e) {
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

      if (match != null) {
        await _player.setSubtitleTrack(match);
      } else {
        await _player.setSubtitleTrack(SubtitleTrack(id, null, null));
      }

      final native = _player.platform as NativePlayer;
      if (!_useLibass) {
        await native.setProperty('sub-visibility', 'no');
      } else {
        await _applyAssOverrideMode();
      }
    } catch (_) {}
  }

  @override
  Future<void> disableSubtitleTrack() async {
    await _player.setSubtitleTrack(SubtitleTrack.no());
  }

  @override
  Future<void> waitForTracksReady() async {
    if (_player.state.tracks.audio.isNotEmpty) {
      return;
    }
    try {
      await _player.stream.tracks
          .firstWhere((t) => t.audio.isNotEmpty)
          .timeout(const Duration(seconds: 5));
    } catch (_) {
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
      await _applyAssOverrideMode();
    } catch (_) {}
  }

  void _enableNativeSubtitleRendering() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        final native = _player.platform as NativePlayer;
        await native.setProperty('sub-visibility', 'no');
        await native.setProperty('sub-ass', 'yes');
        await native.setProperty('sub-ass-override', 'yes');
        await native.setProperty('sub-forced-events-only', 'no');
      } catch (_) {}
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
