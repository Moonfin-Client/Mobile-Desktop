import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialStore {
  final _storage = const FlutterSecureStorage();

  static const _tokenKeyPrefix = 'server_token_';

  /// Save an access token for a server.
  Future<void> saveToken(String serverId, String token) async {
    await _storage.write(key: '$_tokenKeyPrefix$serverId', value: token);
  }

  /// Get the saved access token for a server.
  Future<String?> getToken(String serverId) async {
    return _storage.read(key: '$_tokenKeyPrefix$serverId');
  }

  /// Delete the access token for a server.
  Future<void> deleteToken(String serverId) async {
    await _storage.delete(key: '$_tokenKeyPrefix$serverId');
  }

  /// Delete all stored credentials.
  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
