import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

class EmbyAuthApi implements AuthApi {
  final Dio _dio;

  EmbyAuthApi(this._dio);

  @override
  Future<Map<String, dynamic>> authenticateByName(
    String username,
    String password,
  ) async {
    final response = await _dio.post(
      '/Users/AuthenticateByName',
      data: {'Username': username, 'Pw': password},
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> authenticateWithQuickConnect(String secret) {
    throw UnsupportedError('QuickConnect is not supported on Emby');
  }

  @override
  Future<void> logout() async {
    await _dio.post('/Sessions/Logout');
  }
}
