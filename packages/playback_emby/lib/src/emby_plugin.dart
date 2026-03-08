import 'package:server_core/server_core.dart';
import 'emby_media_stream_resolver.dart';
import 'emby_play_session_service.dart';

class EmbyPlugin {
  final MediaServerClient _client;

  EmbyPlugin(this._client);

  EmbyMediaStreamResolver createStreamResolver() =>
      EmbyMediaStreamResolver(_client);

  EmbyPlaySessionService createPlaySessionService() =>
      EmbyPlaySessionService(_client);
}
