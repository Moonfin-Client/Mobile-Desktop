import 'dart:async';
import 'dart:math';

import 'package:media_kit/media_kit.dart';
import 'package:server_core/server_core.dart';

import '../../preference/user_preferences.dart';
import '../models/aggregated_item.dart';

class ThemeMusicService {
  final MediaServerClient _client;
  final UserPreferences _prefs;

  Player? _player;
  String? _currentThemeSourceId;
  Timer? _fadeTimer;
  double _targetVolume = 0.0;
  final Set<Object> _activeDetailScreens = {};
  bool _fadingOut = false;
  bool _externalAudioActive = false;
  bool _playSuppressed = false;
  int _playGeneration = 0;

  static const _fadeDurationMs = 2000;
  static const _fadeStepMs = 50;
  static const _validTypes = {'Series', 'Movie', 'Season', 'Episode'};

  ThemeMusicService(this._client, this._prefs);

  void registerDetailScreen(Object token) {
    _activeDetailScreens.add(token);
  }

  void unregisterDetailScreen(Object token) {
    _activeDetailScreens.remove(token);
    if (_activeDetailScreens.isEmpty) {
      fadeOutAndStop();
    }
  }

  void setExternalAudioActive(bool active) {
    if (_externalAudioActive == active) return;
    _externalAudioActive = active;
    if (active) {
      fadeOutAndStop();
    }
  }

  Future<void> playForItem(AggregatedItem item) async {
    if (!_prefs.get(UserPreferences.themeMusicEnabled)) return;
    if (_externalAudioActive) return;
    if (_playSuppressed) return;
    if (!_validTypes.contains(item.type)) {
      fadeOutAndStop();
      return;
    }

    final themeItemId = (item.type == 'Episode' || item.type == 'Season') && item.seriesId != null
        ? item.seriesId!
        : item.id;

    if (_currentThemeSourceId == themeItemId && _player != null) {
      if (_fadingOut) {
        _fadeTimer?.cancel();
        _fadeTimer = null;
        _fadingOut = false;
        _fadeIn(_playGeneration);
      }
      return;
    }

    stop();
    final generation = ++_playGeneration;
    _currentThemeSourceId = themeItemId;

    Player? localPlayer;
    try {
      final data = await _client.itemsApi.getThemeMedia(themeItemId);
      if (generation != _playGeneration) return;

      final songsResult = data['ThemeSongsResult'] as Map<String, dynamic>?;
      final songs = (songsResult?['Items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (songs.isEmpty) return;

      final song = songs[Random().nextInt(songs.length)];
      final songId = song['Id'] as String;
      final url = _buildAudioUrl(songId);

      _targetVolume = _prefs.get(UserPreferences.themeMusicVolume) / 100.0;
      localPlayer = Player();
      _player = localPlayer;

      await localPlayer.setVolume(0);
      if (generation != _playGeneration) {
        await _safeDispose(localPlayer);
        return;
      }

      await localPlayer.open(Media(url));
      if (generation != _playGeneration) {
        await _safeDispose(localPlayer);
        return;
      }

      await localPlayer.setPlaylistMode(PlaylistMode.loop);
      if (generation != _playGeneration) {
        await _safeDispose(localPlayer);
        return;
      }

      _fadeIn(generation);
    } catch (_) {
      if (localPlayer != null && (generation != _playGeneration || _player != localPlayer)) {
        await _safeDispose(localPlayer);
      }
    }
  }

  Future<void> _safeDispose(Player player) async {
    try {
      await player.setVolume(0);
    } catch (_) {}
    try {
      await player.pause();
    } catch (_) {}
    try {
      await player.dispose();
    } catch (_) {}
  }

  String _buildAudioUrl(String songId) {
    final token = _client.accessToken ?? '';
    return '${_client.baseUrl}/Audio/$songId/stream?static=true&audioCodec=mp3&audioBitrate=128000&api_key=$token';
  }

  void _fadeIn(int generation) {
    _fadeTimer?.cancel();
    final steps = _fadeDurationMs ~/ _fadeStepMs;
    var step = 0;
    _fadeTimer = Timer.periodic(Duration(milliseconds: _fadeStepMs), (timer) {
      if (generation != _playGeneration || _player == null) {
        timer.cancel();
        return;
      }
      step++;
      final volume = (step / steps) * _targetVolume * 100;
      _player?.setVolume(volume.clamp(0, 100));
      if (step >= steps) timer.cancel();
    });
  }

  void fadeOutAndStop() {
    final player = _player;
    if (player == null || _fadingOut) return;

    _fadeTimer?.cancel();
    _fadingOut = true;
    final generation = _playGeneration;
    final currentVolume = player.state.volume;
    final steps = _fadeDurationMs ~/ _fadeStepMs;
    var step = 0;

    _fadeTimer = Timer.periodic(Duration(milliseconds: _fadeStepMs), (timer) {
      if (generation != _playGeneration || _player != player) {
        timer.cancel();
        return;
      }
      step++;
      final volume = currentVolume * (1.0 - step / steps);
      player.setVolume(volume.clamp(0, 100));
      if (step >= steps) {
        timer.cancel();
        stop();
      }
    });
  }

  void stop() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _fadingOut = false;
    _playGeneration++;
    final player = _player;
    _player = null;
    _currentThemeSourceId = null;
    if (player != null) {
      try {
        player.setVolume(0);
      } catch (_) {}
      try {
        player.pause();
      } catch (_) {}
      unawaited(_safeDispose(player));
    }
  }

  void forceStop({
    Duration suppressionDuration = const Duration(milliseconds: 800),
  }) {
    stop();
    _playSuppressed = true;
    Future<void>.delayed(suppressionDuration).then((_) {
      _playSuppressed = false;
    });
  }

  void dispose() {
    stop();
  }
}
