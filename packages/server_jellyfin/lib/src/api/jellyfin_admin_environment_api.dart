import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

class JellyfinAdminEnvironmentApi implements AdminEnvironmentApi {
  final Dio _dio;

  JellyfinAdminEnvironmentApi(this._dio);

  @override
  Future<List<Map<String, dynamic>>> getDirectoryContents(
    String path, {
    bool? includeFiles,
    bool? includeDirectories,
  }) async {
    final response = await _dio.get(
      '/Environment/DirectoryContents',
      queryParameters: {
        'path': path,
        if (includeFiles != null) 'includeFiles': includeFiles,
        if (includeDirectories != null)
          'includeDirectories': includeDirectories,
      },
    );
    return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> validatePath(String path) async {
    await _dio.post(
      '/Environment/ValidatePath',
      data: {'ValidateWritable': false, 'Path': path},
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getDrives() async {
    final response = await _dio.get('/Environment/Drives');
    return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<String?> getParentPath(String path) async {
    final response = await _dio.get(
      '/Environment/ParentPath',
      queryParameters: {'path': path},
    );
    return response.data as String?;
  }
}
