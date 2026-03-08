import '../store/credential_store.dart';
import 'server_repository.dart';

class SessionRepository {
  final CredentialStore _credentialStore;
  final ServerRepository _serverRepository;

  String? _activeServerId;

  SessionRepository(this._credentialStore, this._serverRepository);

  String? get activeServerId => _activeServerId;

  Future<String?> setActiveServer(String serverId) async {
    _activeServerId = serverId;
    return _credentialStore.getToken(serverId);
  }

  Future<void> saveToken(String serverId, String token) async {
    await _credentialStore.saveToken(serverId, token);
  }

  Future<void> clearSession() async {
    if (_activeServerId != null) {
      await _credentialStore.deleteToken(_activeServerId!);
    }
    _activeServerId = null;
  }
}
