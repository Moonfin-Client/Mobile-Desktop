import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

class EmbyItemsApi implements ItemsApi {
  final Dio _dio;
  final String Function() _getUserId;

  EmbyItemsApi(this._dio, this._getUserId);

  @override
  Future<Map<String, dynamic>> getItems({
    String? parentId,
    List<String>? includeItemTypes,
    String? sortBy,
    String? sortOrder,
    int? startIndex,
    int? limit,
    bool? recursive,
    String? searchTerm,
    String? fields,
  }) async {
    final userId = _getUserId();
    final response = await _dio.get(
      '/Users/$userId/Items',
      queryParameters: {
        if (parentId != null) 'ParentId': parentId,
        if (includeItemTypes != null)
          'IncludeItemTypes': includeItemTypes.join(','),
        if (sortBy != null) 'SortBy': sortBy,
        if (sortOrder != null) 'SortOrder': sortOrder,
        if (startIndex != null) 'StartIndex': startIndex,
        if (limit != null) 'Limit': limit,
        if (recursive != null) 'Recursive': recursive,
        if (searchTerm != null) 'SearchTerm': searchTerm,
        if (fields != null) 'Fields': fields,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getItem(String itemId) async {
    final userId = _getUserId();
    final response = await _dio.get('/Users/$userId/Items/$itemId');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getSimilarItems(
    String itemId, {
    int? limit,
  }) async {
    final response = await _dio.get(
      '/Items/$itemId/Similar',
      queryParameters: {
        if (limit != null) 'Limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getNextUp({
    String? seriesId,
    int? limit,
  }) async {
    final response = await _dio.get('/Shows/NextUp', queryParameters: {
      if (seriesId != null) 'SeriesId': seriesId,
      if (limit != null) 'Limit': limit,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getResumeItems({
    List<String>? includeItemTypes,
    int? limit,
  }) async {
    final userId = _getUserId();
    final response = await _dio.get(
      '/Users/$userId/Items/Resume',
      queryParameters: {
        if (includeItemTypes != null)
          'IncludeItemTypes': includeItemTypes.join(','),
        if (limit != null) 'Limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getLatestItems({
    String? parentId,
    List<String>? includeItemTypes,
    int? limit,
  }) async {
    final userId = _getUserId();
    final response = await _dio.get(
      '/Users/$userId/Items/Latest',
      queryParameters: {
        if (parentId != null) 'ParentId': parentId,
        if (includeItemTypes != null)
          'IncludeItemTypes': includeItemTypes.join(','),
        if (limit != null) 'Limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getSeasons(String seriesId) async {
    final response = await _dio.get('/Shows/$seriesId/Seasons');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getEpisodes(
    String seriesId, {
    String? seasonId,
  }) async {
    final response = await _dio.get(
      '/Shows/$seriesId/Episodes',
      queryParameters: {
        if (seasonId != null) 'SeasonId': seasonId,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
