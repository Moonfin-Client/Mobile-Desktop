import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

class EmbyItemsApi implements ItemsApi {
  final Dio _dio;
  final String Function() _getUserId;

  EmbyItemsApi(this._dio, this._getUserId);

  @override
  Future<Map<String, dynamic>> getItems({
    String? parentId,
    List<String>? ids,
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
    final userId = _getUserId();
    final response = await _dio.get(
      '/Users/$userId/Items',
      queryParameters: {
        if (parentId != null) 'ParentId': parentId,
        if (ids != null) 'Ids': ids.join(','),
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
  Future<List<Map<String, dynamic>>> getAncestors(String itemId) async {
    try {
      final response = await _dio.get('/Items/$itemId/Ancestors');
      return ((response.data as List?) ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
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
    String? parentId,
    int? limit,
    String? fields,
    bool? enableResumable,
  }) async {
    final response = await _dio.get('/Shows/NextUp', queryParameters: {
      if (seriesId != null) 'SeriesId': seriesId,
      if (parentId != null) 'ParentId': parentId,
      if (limit != null) 'Limit': limit,
      if (fields != null) 'Fields': fields,
      if (enableResumable != null) 'EnableResumable': enableResumable,
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
    final userId = _getUserId();
    final response = await _dio.get(
      '/Users/$userId/Items/Resume',
      queryParameters: {
        if (parentId != null) 'ParentId': parentId,
        if (includeItemTypes != null)
          'IncludeItemTypes': includeItemTypes.join(','),
        if (limit != null) 'Limit': limit,
        if (fields != null) 'Fields': fields,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getLatestItems({
    String? parentId,
    List<String>? includeItemTypes,
    int? limit,
    String? fields,
  }) async {
    final userId = _getUserId();
    final response = await _dio.get(
      '/Users/$userId/Items/Latest',
      queryParameters: {
        if (parentId != null) 'ParentId': parentId,
        if (includeItemTypes != null)
          'IncludeItemTypes': includeItemTypes.join(','),
        if (limit != null) 'Limit': limit,
        if (fields != null) 'Fields': fields,
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
    String? fields,
  }) async {
    final response = await _dio.get(
      '/Shows/$seriesId/Episodes',
      queryParameters: {
        if (seasonId != null) 'SeasonId': seasonId,
        if (fields != null) 'Fields': fields,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getThemeMedia(
    String itemId, {
    bool inheritFromParent = true,
  }) async {
    final userId = _getUserId();
    final response = await _dio.get(
      '/Items/$itemId/ThemeMedia',
      queryParameters: {
        'UserId': userId,
        'InheritFromParent': inheritFromParent,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getPlaylists() async {
    final userId = _getUserId();
    final response = await _dio.get('/Users/$userId/Items', queryParameters: {
      'IncludeItemTypes': 'Playlist',
      'Recursive': true,
      'SortBy': 'SortName',
      'SortOrder': 'Ascending',
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getArtists({
    String? parentId,
    String? userId,
    String? sortBy,
    String? sortOrder,
    int? startIndex,
    int? limit,
    bool? recursive,
    String? fields,
    String? nameStartsWith,
    bool? isFavorite,
  }) async {
    final response = await _dio.get('/Artists', queryParameters: {
      if (parentId != null) 'ParentId': parentId,
      if (userId != null) 'UserId': userId,
      if (sortBy != null) 'SortBy': sortBy,
      if (sortOrder != null) 'SortOrder': sortOrder,
      if (startIndex != null) 'StartIndex': startIndex,
      if (limit != null) 'Limit': limit,
      if (recursive != null) 'Recursive': recursive,
      if (fields != null) 'Fields': fields,
      if (nameStartsWith != null) 'NameStartsWith': nameStartsWith,
      if (isFavorite != null) 'IsFavorite': isFavorite,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getAlbumArtists({
    String? parentId,
    String? userId,
    String? sortBy,
    String? sortOrder,
    int? startIndex,
    int? limit,
    bool? recursive,
    String? fields,
    String? nameStartsWith,
    bool? isFavorite,
  }) async {
    final response = await _dio.get('/Artists/AlbumArtists', queryParameters: {
      if (parentId != null) 'ParentId': parentId,
      if (userId != null) 'UserId': userId,
      if (sortBy != null) 'SortBy': sortBy,
      if (sortOrder != null) 'SortOrder': sortOrder,
      if (startIndex != null) 'StartIndex': startIndex,
      if (limit != null) 'Limit': limit,
      if (recursive != null) 'Recursive': recursive,
      if (fields != null) 'Fields': fields,
      if (nameStartsWith != null) 'NameStartsWith': nameStartsWith,
      if (isFavorite != null) 'IsFavorite': isFavorite,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getPlaylistItems(String playlistId) async {
    final response = await _dio.get('/Playlists/$playlistId/Items');
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
  Future<void> removeFromPlaylist(String playlistId, List<String> entryIds) async {
    await _dio.delete('/Playlists/$playlistId/Items', queryParameters: {
      'EntryIds': entryIds.join(','),
    });
  }

  @override
  Future<void> movePlaylistItem(
    String playlistId,
    String playlistItemId,
    int newIndex,
  ) async {
    await _dio.post('/Playlists/$playlistId/Items/$playlistItemId/Move/$newIndex');
  }

  @override
  Future<void> renamePlaylist(String playlistId, String name) async {
    await _dio.post('/Playlists/$playlistId', data: {
      'Name': name,
    });
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    await _dio.delete('/Items/$playlistId');
  }

  @override
  Future<Map<String, dynamic>> getGenres({
    String? parentId,
    String? userId,
    String? sortBy,
    String? sortOrder,
    int? startIndex,
    int? limit,
    bool? recursive,
    String? fields,
  }) async {
    final response = await _dio.get('/Genres', queryParameters: {
      if (parentId != null) 'ParentId': parentId,
      if (userId != null) 'UserId': userId,
      if (sortBy != null) 'SortBy': sortBy,
      if (sortOrder != null) 'SortOrder': sortOrder,
      if (startIndex != null) 'StartIndex': startIndex,
      if (limit != null) 'Limit': limit,
      if (recursive != null) 'Recursive': recursive,
      if (fields != null) 'Fields': fields,
    });
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getLyrics(String itemId) async {
    return const {'Lyrics': []};
  }

  @override
  Future<List<Map<String, dynamic>>> getSpecialFeatures(String itemId) async {
    try {
      final response = await _dio.get('/Items/$itemId/SpecialFeatures');
      final data = response.data;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMediaSegments(String itemId) async {
    return const [];
  }

  @override
  Future<List<Map<String, dynamic>>> searchRemoteSubtitles(
    String itemId, {
    required String language,
    bool? isPerfectMatch,
  }) async {
    throw UnsupportedError(
      'Remote subtitle search is only supported for Jellyfin servers.',
    );
  }

  @override
  Future<void> downloadRemoteSubtitle(String itemId, String subtitleId) async {
    throw UnsupportedError(
      'Remote subtitle download is only supported for Jellyfin servers.',
    );
  }
}
