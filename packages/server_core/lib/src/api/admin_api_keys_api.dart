abstract class AdminApiKeysApi {
  Future<Map<String, dynamic>> getApiKeys();
  Future<void> createApiKey(String appName);
  Future<void> revokeApiKey(String key);
}
