import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

class EmbySystemApi implements SystemApi {
  final Dio _dio;

  EmbySystemApi(this._dio);

  @override
  Future<Map<String, dynamic>> getPublicSystemInfo() async {
    final response = await _dio.get('/System/Info/Public');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getSystemInfo() async {
    final response = await _dio.get('/System/Info');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<bool> ping() async {
    try {
      final response = await _dio.get('/System/Ping');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
