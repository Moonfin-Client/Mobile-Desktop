import 'dart:async';

import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';
import 'package:uuid/uuid.dart';

import '../../data/services/media_server_client_factory.dart';
import '../../util/server_url.dart';
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
    final stored = _authStore.getServers();
    _servers.clear();

    for (final server in stored) {
      final normalizedAddress = normalizeServerBaseUrl(server.address);
      if (normalizedAddress != server.address && normalizedAddress.isNotEmpty) {
        final updated = server.copyWith(address: normalizedAddress);
        await _authStore.putServer(updated);
        _servers.add(updated);
      } else {
        _servers.add(server);
      }
    }
  }

  Server? getServer(String serverId) {
    final index = _servers.indexWhere((s) => s.id == serverId);
    return index >= 0 ? _servers[index] : null;
  }

  Future<Server?> addServer(String address) async {
    address = normalizeServerBaseUrl(address.trim());
    if (address.isEmpty) return null;

    final candidates = _buildCandidates(address);
    _stateController.add(ServerConnecting(address: address));

    for (final candidate in candidates) {
      try {
        final (info, serverType, resolvedUrl) = await _probeServer(candidate);
        final serverAddress = resolvedUrl.isNotEmpty ? resolvedUrl : candidate;

        final existingIndex =
            _servers.indexWhere((s) => s.address == serverAddress);
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
          address: serverAddress,
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

  Future<(Map<String, dynamic>, ServerType, String)> _probeServer(
    String baseUrl,
  ) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      followRedirects: false,
      validateStatus: (status) => status != null && status < 400,
    ));
    configureServerDio(dio);

    try {
      var requestUrl = '$baseUrl/System/Info/Public';
      var response = await dio.get(requestUrl);

      var redirects = 0;
      while (response.statusCode != null &&
          [301, 302, 307, 308].contains(response.statusCode) &&
          redirects < 5) {
        final location = response.headers.value('location');
        if (location == null || location.isEmpty) break;
        requestUrl = Uri.parse(requestUrl).resolve(location).toString();
        response = await dio.get(requestUrl);
        redirects++;
      }

      final data = response.data as Map<String, dynamic>;
      final productName = data['ProductName'] as String?;
      final version = data['Version'] as String?;
      final serverType = ServerType.detect(productName, version);

      var resolvedBaseUrl = baseUrl;
      if (redirects > 0) {
        final finalUri = Uri.parse(requestUrl);
        const probe = '/System/Info/Public';
        if (finalUri.path.endsWith(probe)) {
          final basePath = finalUri.path.substring(
            0,
            finalUri.path.length - probe.length,
          );
          resolvedBaseUrl = normalizeServerBaseUrl(
            '${finalUri.scheme}://${finalUri.authority}$basePath',
          );
        }
      }

      return (data, serverType, resolvedBaseUrl);
    } finally {
      dio.close();
    }
  }

  List<String> _buildCandidates(String address) {
    final candidates = <String>{};

    void addCandidate(String value) {
      final normalized = normalizeServerBaseUrl(value);
      if (normalized.isNotEmpty) {
        candidates.add(normalized);
      }
    }

    if (address.startsWith('http://') || address.startsWith('https://')) {
      addCandidate(address);
      return candidates.toList();
    }

    final hasPort = address.contains(':') && !address.startsWith('[');
    if (hasPort) {
      addCandidate('https://$address');
      addCandidate('http://$address');
      return candidates.toList();
    }

    for (final port in _defaultPorts) {
      addCandidate('https://$address:$port');
    }
    for (final port in _defaultPorts) {
      addCandidate('http://$address:$port');
    }
    return candidates.toList();
  }

  void dispose() {
    _stateController.close();
  }
}
