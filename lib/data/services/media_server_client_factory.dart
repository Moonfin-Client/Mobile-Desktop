import 'package:server_core/server_core.dart';
import 'package:server_jellyfin/server_jellyfin.dart';
import 'package:server_emby/server_emby.dart';

class MediaServerClientFactory {
  final DeviceInfo deviceInfo;
  final Map<String, MediaServerClient> _clients = {};

  MediaServerClientFactory({required this.deviceInfo});

  MediaServerClient getClient({
    required String serverId,
    required ServerType serverType,
    required String baseUrl,
  }) {
    return _clients.putIfAbsent(serverId, () {
      return _createClient(
        serverType: serverType,
        baseUrl: baseUrl,
      );
    });
  }

  MediaServerClient _createClient({
    required ServerType serverType,
    required String baseUrl,
  }) {
    switch (serverType) {
      case ServerType.jellyfin:
        return JellyfinMediaServerClient(
          baseUrl: baseUrl,
          deviceInfo: deviceInfo,
        );
      case ServerType.emby:
        return EmbyMediaServerClient(
          baseUrl: baseUrl,
          deviceInfo: deviceInfo,
        );
    }
  }

  void removeClient(String serverId) {
    _clients.remove(serverId)?.dispose();
  }

  void disposeAll() {
    for (final client in _clients.values) {
      client.dispose();
    }
    _clients.clear();
  }
}
