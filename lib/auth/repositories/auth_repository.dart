import 'dart:async';

import '../models/login_state.dart';
import 'server_repository.dart';
import 'session_repository.dart';
import 'user_repository.dart';

class AuthRepository {
  final ServerRepository _serverRepository;
  final SessionRepository _sessionRepository;
  final UserRepository _userRepository;

  final _stateController = StreamController<LoginState>.broadcast();

  AuthRepository(
    this._serverRepository,
    this._sessionRepository,
    this._userRepository,
  );

  Stream<LoginState> get stateStream => _stateController.stream;

  Future<void> restoreSession() async {
    _stateController.add(const LoginStateLoading());
    await _serverRepository.loadServers();
    if (_serverRepository.servers.isEmpty) {
      _stateController.add(const LoginStateServerSelection());
      return;
    }
    _stateController.add(const LoginStateServerSelection());
  }

  Future<void> login(String serverId, String username, String password) async {
    _stateController.add(const LoginStateLoading());
    try {
      _stateController.add(LoginStateAuthenticated(
        userId: '',
        serverId: serverId,
      ));
    } catch (e) {
      _stateController.add(LoginStateError(message: e.toString()));
    }
  }

  Future<void> logout() async {
    _userRepository.setCurrentUser(null);
    await _sessionRepository.clearSession();
    _stateController.add(const LoginStateServerSelection());
  }

  void dispose() {
    _stateController.close();
  }
}
