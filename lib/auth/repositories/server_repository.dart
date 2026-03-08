import 'package:jellyfin_preference/jellyfin_preference.dart';

import '../models/server.dart';

class ServerRepository {
  final PreferenceStore _store;
  final List<Server> _servers = [];

  ServerRepository(this._store);

  List<Server> get servers => List.unmodifiable(_servers);

  Future<void> loadServers() async {}

  Future<void> addServer(Server server) async {
    _servers.add(server);
  }

  Future<void> removeServer(String serverId) async {
    _servers.removeWhere((s) => s.id == serverId);
  }

  Future<List<Server>> discoverServers() async {
    return [];
  }
}
