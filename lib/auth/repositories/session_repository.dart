import 'dart:async';

import 'package:logger/logger.dart';

import '../../data/services/media_server_client_factory.dart';
import '../../data/services/plugin_sync_service.dart';
import '../../data/services/socket_handler.dart';
import '../../di/modules/playback_module.dart';
import '../../di/modules/server_module.dart';
import '../../preference/preference_constants.dart';
import '../store/authentication_preferences.dart';
import '../store/authentication_store.dart';
import '../store/credential_store.dart';
import 'server_repository.dart';
import 'user_repository.dart';

enum SessionState { ready, restoring, switching }

class SessionRepository {
  final AuthenticationStore _authStore;
  final AuthenticationPreferences _authPrefs;
  final CredentialStore _credentialStore;
  final MediaServerClientFactory _clientFactory;
  final SocketHandler _socketHandler;
  final ServerRepository _serverRepository;
  final UserRepository _userRepository;
  final PluginSyncService _pluginSyncService;
  final _logger = Logger();

  String? _activeServerId;
  String? _activeUserId;
  SessionState _state = SessionState.ready;

  final _stateController = StreamController<SessionState>.broadcast();

  SessionRepository(
    this._authStore,
    this._authPrefs,
    this._credentialStore,
    this._clientFactory,
    this._socketHandler,
    this._serverRepository,
    this._userRepository,
    this._pluginSyncService,
  );

  String? get activeServerId => _activeServerId;
  String? get activeUserId => _activeUserId;
  SessionState get state => _state;
  Stream<SessionState> get stateStream => _stateController.stream;

  Future<bool> restoreSession() async {
    _setState(SessionState.restoring);

    final behavior = _authPrefs.loginBehavior;
    String serverId;
    String userId;

    switch (behavior) {
      case UserSelectBehavior.disabled:
        _setState(SessionState.ready);
        return false;
      case UserSelectBehavior.lastUser:
        serverId = _authPrefs.savedLastServerId;
        userId = _authPrefs.savedLastUserId;
      case UserSelectBehavior.specificUser:
        serverId = _authPrefs.savedAutoLoginServerId;
        userId = _authPrefs.savedAutoLoginUserId;
    }

    if (serverId.isEmpty || userId.isEmpty) {
      _setState(SessionState.ready);
      return false;
    }

    return switchCurrentSession(serverId: serverId, userId: userId);
  }

  Future<bool> switchCurrentSession({
    required String serverId,
    required String userId,
  }) async {
    _setState(SessionState.switching);

    final server = _serverRepository.getServer(serverId);
    if (server == null) {
      _logger.w('Server $serverId not found in stored servers');
      _setState(SessionState.ready);
      return false;
    }

    final users = _authStore.getUsers(serverId);
    final userIndex = users.indexWhere((u) => u.id == userId);
    if (userIndex < 0) {
      _logger.w('User $userId not found for server $serverId');
      _setState(SessionState.ready);
      return false;
    }
    final user = users[userIndex];

    final token = await _credentialStore.getToken(serverId);
    final accessToken = token ?? user.accessToken;

    final client = _clientFactory.getClient(
      serverId: serverId,
      serverType: server.serverType,
      baseUrl: server.address,
    );

    client.accessToken = accessToken;
    client.userId = userId;

    setActiveServerClient(client);
    setActiveStreamResolver(client);
    _socketHandler.connectTo(client);

    _activeServerId = serverId;
    _activeUserId = userId;

    _userRepository.setCurrentUser(user);
    await _authPrefs.setLastServerId(serverId);
    await _authPrefs.setLastUserId(userId);

    await _pluginSyncService.syncOnLogin(client);

    _setState(SessionState.ready);
    return true;
  }

  Future<void> destroyCurrentSession() async {
    _socketHandler.disconnect();

    if (_activeServerId != null) {
      _clientFactory.removeClient(_activeServerId!);
    }

    _activeServerId = null;
    _activeUserId = null;
    _userRepository.setCurrentUser(null);
    _setState(SessionState.ready);
  }

  void _setState(SessionState state) {
    _state = state;
    _stateController.add(state);
  }

  void dispose() {
    _stateController.close();
  }
}
