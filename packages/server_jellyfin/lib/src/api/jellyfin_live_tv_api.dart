import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

class JellyfinLiveTvApi implements LiveTvApi {
  final Dio _dio;

  JellyfinLiveTvApi(this._dio);

  @override
  Future<Map<String, dynamic>> getChannels({
    int? startIndex,
    int? limit,
    String? sortBy,
    String? sortOrder,
    String? fields,
    bool? enableTotalRecordCount,
    String? userId,
  }) async {
    final response = await _dio.get('/LiveTv/Channels', queryParameters: {
      if (startIndex != null) 'StartIndex': startIndex,
      if (limit != null) 'Limit': limit,
      if (sortBy != null) 'SortBy': sortBy,
      if (sortOrder != null) 'SortOrder': sortOrder,
      if (fields != null) 'Fields': fields,
      if (enableTotalRecordCount != null) 'EnableTotalRecordCount': enableTotalRecordCount,
      if (userId != null) 'UserId': userId,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getGuide({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? channelIds,
    String? fields,
    bool? enableTotalRecordCount,
    String? userId,
  }) async {
    final response = await _dio.post('/LiveTv/Programs', data: {
      if (startDate != null) 'MinEndDate': startDate.toUtc().toIso8601String(),
      if (endDate != null) 'MaxStartDate': endDate.toUtc().toIso8601String(),
      if (channelIds != null && channelIds.isNotEmpty) 'ChannelIds': channelIds,
      if (fields != null) 'Fields': fields.split(',').map((f) => f.trim()).toList(),
      'EnableTotalRecordCount': enableTotalRecordCount ?? false,
      if (userId != null) 'UserId': userId,
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
  Future<Map<String, dynamic>> getRecordings({
    int? limit,
    String? fields,
    bool? enableImages,
    bool? isSeries,
    bool? isMovie,
    bool? isSports,
    bool? isKids,
  }) async {
    final response = await _dio.get('/LiveTv/Recordings', queryParameters: {
      if (limit != null) 'Limit': limit,
      if (fields != null) 'Fields': fields,
      if (enableImages != null) 'EnableImages': enableImages,
      if (isSeries != null) 'IsSeries': isSeries,
      if (isMovie != null) 'IsMovie': isMovie,
      if (isSports != null) 'IsSports': isSports,
      if (isKids != null) 'IsKids': isKids,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getTimers() async {
    final response = await _dio.get('/LiveTv/Timers');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getSeriesTimers() async {
    final response = await _dio.get('/LiveTv/SeriesTimers');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> cancelTimer(String timerId) async {
    await _dio.delete('/LiveTv/Timers/$timerId');
  }

  @override
  Future<void> cancelSeriesTimer(String seriesTimerId) async {
    await _dio.delete('/LiveTv/SeriesTimers/$seriesTimerId');
  }
}
