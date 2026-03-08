import 'package:playback_core/playback_core.dart';
import 'package:server_core/server_core.dart';

class EmbyPlaySessionService implements PlayerService {
  final MediaServerClient _client;

  EmbyPlaySessionService(this._client);

  @override
  Future<void> onPlaybackStart(dynamic mediaItem) async {
    await _client.playbackApi.reportPlaybackStart({
      'ItemId': mediaItem['Id'],
      'CanSeek': true,
      'IsPaused': false,
    });
  }

  @override
  Future<void> onPlaybackProgress(Duration position) async {
    await _client.playbackApi.reportPlaybackProgress({
      'PositionTicks': position.inMicroseconds * 10,
      'IsPaused': false,
    });
  }

  @override
  Future<void> onPlaybackStop(Duration position) async {
    await _client.playbackApi.reportPlaybackStopped({
      'PositionTicks': position.inMicroseconds * 10,
    });
  }

  @override
  void dispose() {}
}
