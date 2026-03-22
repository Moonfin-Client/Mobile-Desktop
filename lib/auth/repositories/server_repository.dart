import 'dart:async';

import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';
import 'package:uuid/uuid.dart';

import '../../data/services/media_server_client_factory.dart';
import '../models/server.dart';
import '../models/server_addition_state.dart';
import '../store/authentication_store.dart';

class ServerRepository {
  final AuthenticationStore _authStore;
  final MediaServerClientFactory _clientFactory;

  final List<Server> _servers = [];
  final _stateController = StreamController<ServerAdditionState>.broadcast();

  ServerRepository(this._authStore, this._clientFactory);

  List<Server> get servers => List.unmodifiable(_servers);
  Stream<ServerAdditionState> get additionState => _stateController.stream;

  static const _defaultPorts = [8096, 8920];

  Future<void> loadStoredServers() async {
    _servers
      ..clear()
      ..addAll(_authStore.getServers());
  }

  Server? getServer(String serverId) {
    final index = _servers.indexWhere((s) => s.id == serverId);
    return index >= 0 ? _servers[index] : null;
  }

  Future<Server?> addServer(String address) async {
    address = address.trim();
    if (address.isEmpty) return null;

    final candidates = _buildCandidates(address);
    _stateController.add(ServerConnecting(address: address));

    for (final candidate in candidates) {
      try {
        final (info, serverType) = await _probeServer(candidate);

        final existingIndex =
            _servers.indexWhere((s) => s.address == candidate);
        if (existingIndex >= 0) {
          final existing = _servers[existingIndex];
          final updated = existing.copyWith(
            name: info['ServerName'] as String? ?? existing.name,
            version: info['Version'] as String? ?? existing.version,
            serverType: serverType,
            dateLastAccessed: DateTime.now(),
          );
          await _authStore.putServer(updated);
          _servers[existingIndex] = updated;
          _stateController.add(
            ServerConnected(id: updated.id, publicInfo: info),
          );
          return updated;
        }

        final server = Server(
          id: const Uuid().v4(),
          name: info['ServerName'] as String? ?? address,
          address: candidate,
          version: info['Version'] as String? ?? '',
          serverType: serverType,
          loginDisclaimer: info['LoginDisclaimer'] as String?,
          setupCompleted: info['StartupWizardCompleted'] as bool? ?? true,
          dateAdded: DateTime.now(),
        );

        await _authStore.putServer(server);
        _servers.add(server);
        _stateController.add(ServerConnected(id: server.id, publicInfo: info));
        return server;
      } catch (_) {}
    }

    _stateController.add(ServerUnableToConnect(candidatesTried: candidates));
    return null;
  }

  Future<void> updateServer(Server server) async {
    final index = _servers.indexWhere((s) => s.id == server.id);
    if (index >= 0) {
      _servers[index] = server;
    }
    await _authStore.putServer(server);
  }

  Future<void> deleteServer(String serverId) async {
    _servers.removeWhere((s) => s.id == serverId);
    _clientFactory.removeClient(serverId);
    await _authStore.removeServer(serverId);
  }

  Future<(Map<String, dynamic>, ServerType)> _probeServer(
    String baseUrl,
  ) async {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ));
    configureServerDio(dio);

    try {
      final response = await dio.get('/System/Info/Public');
      final data = response.data as Map<String, dynamic>;
      final productName = data['ProductName'] as String?;
      final version = data['Version'] as String?;
      final serverType = ServerType.detect(productName, version);
      return (data, serverType);
    } finally {
      dio.close();
    }
  }

  List<String> _buildCandidates(String address) {
    if (address.startsWith('http://') || address.startsWith('https://')) {
      return [address];
    }

    final hasPort = address.contains(':') && !address.startsWith('[');
    if (hasPort) {
      return ['https://$address', 'http://$address'];
    }

    final candidates = <String>[];
    for (final port in _defaultPorts) {
      candidates.add('https://$address:$port');
    }
    for (final port in _defaultPorts) {
      candidates.add('http://$address:$port');
    }
    return candidates;
  }

  void dispose() {
    _stateController.close();
  }
}
