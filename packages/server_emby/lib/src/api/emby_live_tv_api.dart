import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

class EmbyLiveTvApi implements LiveTvApi {
  final Dio _dio;

  EmbyLiveTvApi(this._dio);

  @override
  Future<Map<String, dynamic>> getChannels({
    int? startIndex,
    int? limit,
  }) async {
    final response = await _dio.get('/LiveTv/Channels', queryParameters: {
      if (startIndex != null) 'StartIndex': startIndex,
      if (limit != null) 'Limit': limit,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getGuide({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _dio.get('/LiveTv/Programs', queryParameters: {
      if (startDate != null) 'MinStartDate': startDate.toIso8601String(),
      if (endDate != null) 'MaxEndDate': endDate.toIso8601String(),
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getRecommendedPrograms({int? limit}) async {
    final response = await _dio.get(
      '/LiveTv/Programs/Recommended',
      queryParameters: {if (limit != null) 'Limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getRecordings() async {
    final response = await _dio.get('/LiveTv/Recordings');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getTimers() async {
    final response = await _dio.get('/LiveTv/Timers');
    return response.data as Map<String, dynamic>;
  }
}
