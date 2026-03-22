import 'dart:async';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:server_core/server_core.dart';

import '../models/login_state.dart';
import '../models/user.dart';
import '../store/authentication_store.dart';
import '../store/authentication_preferences.dart';
import 'session_repository.dart';
import 'user_repository.dart';

class AuthRepository {
  final AuthenticationStore _authStore;
  final AuthenticationPreferences _authPrefs;
  final SessionRepository _sessionRepository;
  final UserRepository _userRepository;
  final _logger = Logger();

  final _stateController = StreamController<LoginState>.broadcast();

  AuthRepository(
    this._authStore,
    this._authPrefs,
    this._sessionRepository,
    this._userRepository,
  );

  Stream<LoginState> get stateStream => _stateController.stream;

  Future<LoginState> authenticate({
    required MediaServerClient client,
    required String serverId,
    required String username,
    required String password,
  }) async {
    _stateController.add(const Authenticating());
    try {
      final result = await client.authApi.authenticateByName(
        username,
        password,
      );
      return _handleAuthResult(
        result: result,
        client: client,
        serverId: serverId,
        fallbackName: username,
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      _logger.e('Authentication failed', error: e);
      final state = ApiClientError(error: e.toString());
      _stateController.add(state);
      return state;
    }
  }

  Future<LoginState> authenticateWithQuickConnect({
    required MediaServerClient client,
    required String serverId,
    required String secret,
  }) async {
    _stateController.add(const Authenticating());
    try {
      final result = await client.authApi.authenticateWithQuickConnect(secret);
      return _handleAuthResult(
        result: result,
        client: client,
        serverId: serverId,
        fallbackName: '',
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      _logger.e('QuickConnect auth failed', error: e);
      final state = ApiClientError(error: e.toString());
      _stateController.add(state);
      return state;
    }
  }

  Future<LoginState> _handleAuthResult({
    required Map<String, dynamic> result,
    required MediaServerClient client,
    required String serverId,
    required String fallbackName,
  }) async {
    final accessToken = result['AccessToken'] as String?;
    final userJson = result['User'] as Map<String, dynamic>?;
    final userId = userJson?['Id'] as String? ?? result['UserId'] as String?;
    final userName = userJson?['Name'] as String? ?? fallbackName;
    final imageTag =
        (userJson?['PrimaryImageTag'] as String?) ??
        ((userJson?['ImageTags'] as Map<String, dynamic>?)?['Primary']
            as String?);
    final policyJson = userJson?['Policy'] as Map<String, dynamic>?;
    final isAdmin = policyJson?['IsAdministrator'] as bool? ?? false;

    if (accessToken == null || userId == null) {
      const state = ApiClientError(error: 'Invalid auth response');
      _stateController.add(state);
      return state;
    }

    client.accessToken = accessToken;
    client.userId = userId;

    final user = PrivateUser(
      id: userId,
      name: userName,
      serverId: serverId,
      accessToken: accessToken,
      lastUsed: DateTime.now(),
      imageTag: imageTag,
      isAdministrator: isAdmin,
    );

    await _authStore.putUser(user);
    await _authPrefs.setLastServerId(serverId);
    await _authPrefs.setLastUserId(userId);
    _userRepository.setCurrentUser(user);

    final state = Authenticated(userId: userId, serverId: serverId);
    _stateController.add(state);
    return state;
  }

  LoginState _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) {
      final state = ApiClientError(error: 'Invalid username or password');
      _stateController.add(state);
      return state;
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      const state = ServerUnavailable();
      _stateController.add(state);
      return state;
    }
    final detail = e.error?.toString() ?? e.message ?? 'unknown error';
    final state = ApiClientError(
      error: 'Connection failed (${e.type.name}): $detail',
    );
    _stateController.add(state);
    return state;
  }

  Future<void> logout(MediaServerClient client) async {
    try {
      await client.authApi.logout();
    } catch (_) {}

    final user = _userRepository.currentUser;
    if (user != null) {
      await _authStore.removeUser(user.serverId, user.id);
    }

    _userRepository.setCurrentUser(null);
    await _sessionRepository.destroyCurrentSession();
    _stateController.add(const RequireSignIn());
  }

  String? getUserImageUrl(MediaServerClient client, User user) {
    if (user.imageTag == null) return null;
    return client.imageApi.getUserImageUrl(user.id);
  }

  void dispose() {
    _stateController.close();
  }
}
