import 'package:playback_core/playback_core.dart';
import 'package:server_core/server_core.dart';

class EmbyMediaStreamResolver implements MediaStreamResolver {
  final MediaServerClient _client;

  EmbyMediaStreamResolver(this._client);

  @override
  Future<String> resolve(dynamic mediaItem) async {
    final itemId = mediaItem['Id'] as String;
    final playbackInfo = await _client.playbackApi.getPlaybackInfo(itemId);
    final mediaSources = playbackInfo['MediaSources'] as List?;

    if (mediaSources == null || mediaSources.isEmpty) {
      throw Exception('No media sources available for item $itemId');
    }

    final source = mediaSources.first as Map<String, dynamic>;
    final mediaSourceId = source['Id'] as String?;

    return _client.playbackApi.getStreamUrl(
      itemId,
      mediaSourceId: mediaSourceId,
    );
  }
}
