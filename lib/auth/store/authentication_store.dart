import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../models/server.dart';
import '../models/user.dart';

class AuthenticationStore {
  static const _fileName = 'authentication_store.json';
  static const _currentVersion = 2;

  final _logger = Logger();
  File? _file;
  Map<String, dynamic> _data = {'version': _currentVersion, 'servers': {}};

  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    _file = File('${dir.path}/$_fileName');

    if (await _file!.exists()) {
      try {
        final contents = await _file!.readAsString();
        _data = jsonDecode(contents) as Map<String, dynamic>;
        if (_data['version'] != _currentVersion) {
          _data = {'version': _currentVersion, 'servers': {}};
        }
      } catch (e) {
        _logger.e('Failed to load authentication store', error: e);
        _data = {'version': _currentVersion, 'servers': {}};
      }
    }
  }

  Future<void> _save() async {
    final file = _file;
    if (file == null) return;
    await file.writeAsString(jsonEncode(_data));
  }

  Map<String, dynamic> get _servers {
    final servers = _data['servers'];
    if (servers is Map) return Map<String, dynamic>.from(servers);
    return {};
  }

  List<Server> getServers() {
    return _servers.entries.map((entry) {
      return Server.fromJson(
        entry.key,
        Map<String, dynamic>.from(entry.value as Map),
      );
    }).toList();
  }

  Server? getServer(String serverId) {
    final raw = _servers[serverId];
    if (raw == null) return null;
    final serverData = Map<String, dynamic>.from(raw as Map);
    return Server.fromJson(serverId, serverData);
  }

  Future<void> putServer(Server server) async {
    final servers = Map<String, dynamic>.from(_servers);
    final serverJson = Map<String, dynamic>.from(server.toJson());
    final existing = servers[server.id];
    if (existing is Map) {
      final existingUsers = (existing as Map<String, dynamic>)['users'];
      if (existingUsers != null) {
        serverJson['users'] = existingUsers;
      }
    }
    servers[server.id] = serverJson;
    _data['servers'] = servers;
    await _save();
  }

  Future<void> removeServer(String serverId) async {
    final servers = Map<String, dynamic>.from(_servers);
    servers.remove(serverId);
    _data['servers'] = servers;
    await _save();
  }

  List<PrivateUser> getUsers(String serverId) {
    final raw = _servers[serverId];
    if (raw == null) return [];
    final serverData = Map<String, dynamic>.from(raw as Map);

    final usersRaw = serverData['users'];
    final users = usersRaw is Map ? Map<String, dynamic>.from(usersRaw) : <String, dynamic>{};
    return users.entries.map((entry) {
      return PrivateUser.fromJson(
        entry.key,
        serverId,
        Map<String, dynamic>.from(entry.value as Map),
      );
    }).toList();
  }

  PrivateUser? getUser(String serverId, String userId) {
    final raw = _servers[serverId];
    if (raw == null) return null;
    final serverData = Map<String, dynamic>.from(raw as Map);

    final usersRaw = serverData['users'];
    final users = usersRaw is Map ? Map<String, dynamic>.from(usersRaw) : <String, dynamic>{};
    final userRaw = users[userId];
    if (userRaw == null) return null;
    final userData = Map<String, dynamic>.from(userRaw as Map);

    return PrivateUser.fromJson(userId, serverId, userData);
  }

  Future<void> putUser(PrivateUser user) async {
    final servers = Map<String, dynamic>.from(_servers);
    final serverData =
        Map<String, dynamic>.from(servers[user.serverId] as Map? ?? {});
    final users =
        Map<String, dynamic>.from(serverData['users'] as Map? ?? {});

    users[user.id] = user.toJson();
    serverData['users'] = users;
    servers[user.serverId] = serverData;
    _data['servers'] = servers;
    await _save();
  }

  Future<void> removeUser(String serverId, String userId) async {
    final servers = Map<String, dynamic>.from(_servers);
    final serverData = servers[serverId] as Map<String, dynamic>?;
    if (serverData == null) return;

    final mutableServerData = Map<String, dynamic>.from(serverData);
    final users =
        Map<String, dynamic>.from(mutableServerData['users'] as Map? ?? {});
    users.remove(userId);
    mutableServerData['users'] = users;
    servers[serverId] = mutableServerData;
    _data['servers'] = servers;
    await _save();
  }
}
