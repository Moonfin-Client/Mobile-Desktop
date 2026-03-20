import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

class JellyfinAdminApiKeysApi implements AdminApiKeysApi {
  final Dio _dio;

  JellyfinAdminApiKeysApi(this._dio);

  @override
  Future<Map<String, dynamic>> getApiKeys() async {
    final response = await _dio.get('/Auth/Keys');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is List) {
      return {'Items': data};
    }
    return const {'Items': <Map<String, dynamic>>[]};
  }

  @override
  Future<void> createApiKey(String appName) async {
    await _dio.post(
      '/Auth/Keys',
      queryParameters: {'app': appName},
    );
  }

  @override
  Future<void> revokeApiKey(String key) async {
    await _dio.delete('/Auth/Keys/${Uri.encodeComponent(key)}');
  }
}
