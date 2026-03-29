import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class CredentialStore {
  final _storage = const FlutterSecureStorage();
  bool _secureStorageUnavailable = false;

  bool get secureStorageUnavailable => _secureStorageUnavailable;

  bool consumeSecureStorageUnavailable() {
    final current = _secureStorageUnavailable;
    _secureStorageUnavailable = false;
    return current;
  }

  void _markUnavailable() {
    _secureStorageUnavailable = true;
  }

  static const _tokenKeyPrefix = 'server_token_';

  /// Save an access token for a server.
  Future<void> saveToken(String serverId, String token) async {
    try {
      await _storage.write(key: '$_tokenKeyPrefix$serverId', value: token);
    } on PlatformException {
      _markUnavailable();
    }
  }

  /// Get the saved access token for a server.
  Future<String?> getToken(String serverId) async {
    try {
      return _storage.read(key: '$_tokenKeyPrefix$serverId');
    } on PlatformException {
      _markUnavailable();
      return null;
    }
  }

  /// Delete the access token for a server.
  Future<void> deleteToken(String serverId) async {
    try {
      await _storage.delete(key: '$_tokenKeyPrefix$serverId');
    } on PlatformException {
      _markUnavailable();
    }
  }

  /// Delete all stored credentials.
  Future<void> clear() async {
    try {
      await _storage.deleteAll();
    } on PlatformException {
      _markUnavailable();
    }
  }
}
