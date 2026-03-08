import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

class EmbySessionApi implements SessionApi {
  final Dio _dio;

  EmbySessionApi(this._dio);

  @override
  Future<void> reportCapabilities(Map<String, dynamic> capabilities) async {
    await _dio.post('/Sessions/Capabilities/Full', data: capabilities);
  }

  @override
  Future<List<Map<String, dynamic>>> getSessions() async {
    final response = await _dio.get('/Sessions');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> sendCommand(
    String sessionId,
    Map<String, dynamic> command,
  ) async {
    await _dio.post('/Sessions/$sessionId/Command', data: command);
  }
}
