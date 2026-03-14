import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

class JellyfinItemsApi implements ItemsApi {
  final Dio _dio;

  JellyfinItemsApi(this._dio);

  @override
  Future<Map<String, dynamic>> getItems({
    String? parentId,
    List<String>? includeItemTypes,
    List<String>? excludeItemTypes,
    String? sortBy,
    String? sortOrder,
    int? startIndex,
    int? limit,
    bool? recursive,
    String? searchTerm,
    String? fields,
    List<String>? personIds,
    List<String>? artistIds,
    List<String>? filters,
    List<String>? seriesStatus,
    String? nameStartsWith,
    List<String>? genreIds,
    List<String>? genres,
    bool? isFavorite,
    bool? collapseBoxSetItems,
    bool? enableTotalRecordCount,
  }) async {
    final response = await _dio.get('/Items', queryParameters: {
      if (parentId != null) 'ParentId': parentId,
      if (includeItemTypes != null)
        'IncludeItemTypes': includeItemTypes.join(','),
      if (excludeItemTypes != null)
        'ExcludeItemTypes': excludeItemTypes.join(','),
      if (sortBy != null) 'SortBy': sortBy,
      if (sortOrder != null) 'SortOrder': sortOrder,
      if (startIndex != null) 'StartIndex': startIndex,
      if (limit != null) 'Limit': limit,
      if (recursive != null) 'Recursive': recursive,
      if (searchTerm != null) 'SearchTerm': searchTerm,
      if (fields != null) 'Fields': fields,
      if (personIds != null) 'PersonIds': personIds.join(','),
      if (artistIds != null) 'ArtistIds': artistIds.join(','),
      if (filters != null) 'Filters': filters.join(','),
      if (seriesStatus != null) 'SeriesStatus': seriesStatus.join(','),
      if (nameStartsWith != null) 'NameStartsWith': nameStartsWith,
      if (genreIds != null) 'GenreIds': genreIds.join(','),
      if (genres != null) 'Genres': genres.join(','),
      if (isFavorite != null) 'IsFavorite': isFavorite,
      if (collapseBoxSetItems != null) 'CollapseBoxSetItems': collapseBoxSetItems,
      if (enableTotalRecordCount != null) 'EnableTotalRecordCount': enableTotalRecordCount,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getItem(String itemId) async {
    final response = await _dio.get('/Items/$itemId');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getSimilarItems(
    String itemId, {
    int? limit,
  }) async {
    final response = await _dio.get('/Items/$itemId/Similar', queryParameters: {
      if (limit != null) 'Limit': limit,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getNextUp({
    String? seriesId,
    String? parentId,
    int? limit,
    String? fields,
  }) async {
    final response = await _dio.get('/Shows/NextUp', queryParameters: {
      if (seriesId != null) 'SeriesId': seriesId,
      if (parentId != null) 'ParentId': parentId,
      if (limit != null) 'Limit': limit,
      if (fields != null) 'Fields': fields,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getResumeItems({
    String? parentId,
    List<String>? includeItemTypes,
    int? limit,
    String? fields,
  }) async {
    final response = await _dio.get('/UserItems/Resume', queryParameters: {
      if (parentId != null) 'ParentId': parentId,
      if (includeItemTypes != null)
        'IncludeItemTypes': includeItemTypes.join(','),
      if (limit != null) 'Limit': limit,
      if (fields != null) 'Fields': fields,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getLatestItems({
    String? parentId,
    List<String>? includeItemTypes,
    int? limit,
    String? fields,
  }) async {
    final response = await _dio.get('/Items/Latest', queryParameters: {
      if (parentId != null) 'ParentId': parentId,
      if (includeItemTypes != null)
        'IncludeItemTypes': includeItemTypes.join(','),
      if (limit != null) 'Limit': limit,
      if (fields != null) 'Fields': fields,
    });
    final data = response.data;
    if (data is List) return {'Items': data, 'TotalRecordCount': data.length};
    return data as Map<String, dynamic>;
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
    final response =
        await _dio.get('/Shows/$seriesId/Episodes', queryParameters: {
      if (seasonId != null) 'SeasonId': seasonId,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getThemeMedia(
    String itemId, {
    bool inheritFromParent = true,
  }) async {
    final response = await _dio.get(
      '/Items/$itemId/ThemeMedia',
      queryParameters: {'InheritFromParent': inheritFromParent},
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getPlaylists() async {
    final response = await _dio.get('/Items', queryParameters: {
      'IncludeItemTypes': 'Playlist',
      'Recursive': true,
      'SortBy': 'SortName',
      'SortOrder': 'Ascending',
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> createPlaylist({
    required String name,
    List<String>? itemIds,
  }) async {
    final response = await _dio.post('/Playlists', data: {
      'Name': name,
      if (itemIds != null) 'Ids': itemIds,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> addToPlaylist(String playlistId, List<String> itemIds) async {
    await _dio.post('/Playlists/$playlistId/Items', queryParameters: {
      'Ids': itemIds.join(','),
    });
  }

  @override
  Future<Map<String, dynamic>> getGenres({
    String? parentId,
    String? sortBy,
    String? sortOrder,
    int? startIndex,
    int? limit,
  }) async {
    final response = await _dio.get('/Genres', queryParameters: {
      if (parentId != null) 'ParentId': parentId,
      if (sortBy != null) 'SortBy': sortBy,
      if (sortOrder != null) 'SortOrder': sortOrder,
      if (startIndex != null) 'StartIndex': startIndex,
      if (limit != null) 'Limit': limit,
    });
    return response.data as Map<String, dynamic>;
  }
}
