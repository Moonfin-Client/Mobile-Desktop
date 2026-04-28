import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:server_core/server_core.dart';
import 'package:dio/dio.dart';

import '../../preference/user_preferences.dart';
import '../models/aggregated_item.dart';
import '../models/home_row.dart';
import '../utils/latest_media_row_normalizer.dart';
import '../utils/playlist_utils.dart';

class RowDataSource {
  final MediaServerClient _client;

  static const _defaultLimit = 15;
  static const _maxItems = 100;

  static const _fields =
      'Type,UserData,Overview,Genres,CommunityRating,CriticRating,'
      'OfficialRating,RunTimeTicks,ProductionYear,SeriesName,'
      'ParentIndexNumber,IndexNumber,Status,ImageTags,BackdropImageTags,'
      'ParentBackdropItemId,ParentBackdropImageTags,ParentThumbItemId,'
      'ParentThumbImageTag,SeriesId,SeriesPrimaryImageTag,ProviderIds,'
      'ParentLogoItemId,ParentLogoImageTag,MediaStreams';
    static const _fallbackFields =
      'Type,UserData,OfficialRating,RunTimeTicks,ProductionYear,SeriesName,'
      'ParentIndexNumber,IndexNumber,ImageTags,BackdropImageTags,'
      'ParentBackdropItemId,ParentBackdropImageTags,ParentThumbItemId,'
      'ParentThumbImageTag,SeriesId,SeriesPrimaryImageTag,'
      'ParentLogoItemId,ParentLogoImageTag,MediaStreams';
    static const _minimalFields =
      'Type,UserData,RunTimeTicks,ProductionYear,ImageTags,BackdropImageTags,'
      'ParentBackdropItemId,ParentBackdropImageTags,SeriesId,MediaStreams';

  RowDataSource(this._client);

  ImageApi get imageApi => _client.imageApi;

  Future<HomeRow> loadOnNow(String serverId) async {
    final response = await _client.liveTvApi.getRecommendedPrograms(
      limit: _defaultLimit,
    );
    return _buildRow(
      id: 'liveTvOnNow',
      title: 'On Now',
      response: response,
      serverId: serverId,
      rowType: HomeRowType.liveTvOnNow,
    );
  }

  Future<HomeRow> loadResume(String serverId) async {
    final response = await _getResumeItemsWithFallback(
      includeItemTypes: ['Movie', 'Episode'],
      limit: _defaultLimit,
    );
    return _buildRow(
      id: 'resume',
      title: 'Continue Watching',
      response: response,
      serverId: serverId,
      rowType: HomeRowType.resume,
    );
  }

  Future<HomeRow> loadResumeAudio(String serverId) async {
    final response = await _getResumeItemsWithFallback(
      includeItemTypes: ['Audio'],
      limit: _defaultLimit,
    );
    return _buildRow(
      id: 'resumeAudio',
      title: 'Continue Listening',
      response: response,
      serverId: serverId,
      rowType: HomeRowType.resumeAudio,
    );
  }

  Future<HomeRow> loadNextUp(String serverId) async {
    final response = await _getNextUpWithFallback(
      limit: _defaultLimit,
      enableResumable: false,
    );
    return _buildRow(
      id: 'nextUp',
      title: 'Next Up',
      response: response,
      serverId: serverId,
      rowType: HomeRowType.nextUp,
    );
  }

  Future<HomeRow> loadResumeRelaxed(String serverId) async {
    final response = await getResumeItemsRelaxed(
      includeItemTypes: const ['Movie', 'Episode'],
      limit: _defaultLimit,
    );
    return _buildRow(
      id: 'resume',
      title: 'Continue Watching',
      response: response,
      serverId: serverId,
      rowType: HomeRowType.resume,
    );
  }

  Future<HomeRow> loadNextUpRelaxed(String serverId) async {
    final response = await getNextUpRelaxed(
      limit: _defaultLimit,
    );
    return _buildRow(
      id: 'nextUp',
      title: 'Next Up',
      response: response,
      serverId: serverId,
      rowType: HomeRowType.nextUp,
    );
  }

  Future<HomeRow> loadLatestMedia(
    String parentId,
    String libraryName,
    String serverId, [
    String? collectionType,
  ]) async {
    final fetchLimit = latestMediaFetchLimitForCollection(
      collectionType,
      defaultLimit: _defaultLimit,
      maxLimit: _maxItems,
    );
    final response = await _getLatestItemsWithFallback(
      parentId: parentId,
      limit: fetchLimit,
    );
    final items = normalizeLatestMediaItems(
      _parseItems(response, serverId),
      collectionType: collectionType,
      limit: _defaultLimit,
    );
    return HomeRow(
      id: 'latest_$parentId',
      title: 'Latest $libraryName',
      items: items,
      rowType: HomeRowType.latestMedia,
      totalCount: items.length,
    );
  }

  Future<HomeRow> loadPlaylists(String serverId, {String? mediaType}) async {
    final response = await _getItemsWithFallback(
      includeItemTypes: ['Playlist'],
      sortBy: 'SortName',
      sortOrder: 'Ascending',
      recursive: true,
      limit: _defaultLimit,
    );
    var row = _buildRow(
      id: 'playlists',
      title: 'Playlists',
      response: response,
      serverId: serverId,
      rowType: HomeRowType.playlists,
    );
    row = row.copyWith(
      items: await filterBrowsablePlaylists(
        _client,
        row.items,
        mediaType: mediaType,
      ),
    );
    return row;
  }

  Future<HomeRow> loadLibraryTiles(
    String serverId, [
    HomeRowType rowType = HomeRowType.libraryTiles,
  ]) async {
    final response = await _client.userViewsApi.getUserViews();
    return _buildRow(
      id:
          rowType == HomeRowType.libraryTilesSmall
              ? 'libraryTilesSmall'
              : 'libraryTiles',
      title: 'My Media',
      response: response,
      serverId: serverId,
      rowType: rowType,
    );
  }

  Future<HomeRow> loadLibraryResume(String parentId, String serverId) async {
    final response = await _getResumeItemsWithFallback(
      parentId: parentId,
      includeItemTypes: ['Video'],
      limit: _defaultLimit,
    );
    return _buildRow(
      id: 'resume_$parentId',
      title: 'Continue Watching',
      response: response,
      serverId: serverId,
      rowType: HomeRowType.resume,
    );
  }

  Future<HomeRow> loadLibraryNextUp(String parentId, String serverId) async {
    final response = await _getNextUpWithFallback(
      parentId: parentId,
      limit: _defaultLimit,
    );
    return _buildRow(
      id: 'nextUp_$parentId',
      title: 'Next Up',
      response: response,
      serverId: serverId,
      rowType: HomeRowType.nextUp,
    );
  }

  Future<HomeRow> loadLibraryFavorites(
    String parentId,
    String serverId, {
    List<String>? includeItemTypes,
  }) async {
    final response = await _getItemsWithFallback(
      parentId: parentId,
      isFavorite: true,
      sortBy: 'SortName',
      sortOrder: 'Ascending',
      recursive: true,
      limit: _defaultLimit,
      includeItemTypes: includeItemTypes,
    );
    return _buildRow(
      id: 'favorites_$parentId',
      title: 'Favorites',
      response: response,
      serverId: serverId,
      rowType: HomeRowType.latestMedia,
    );
  }

  Future<HomeRow> loadLibraryCollections(
    String parentId,
    String serverId,
  ) async {
    final response = await _getItemsWithFallback(
      parentId: parentId,
      includeItemTypes: ['BoxSet'],
      sortBy: 'SortName',
      sortOrder: 'Ascending',
      recursive: true,
      limit: _defaultLimit,
    );
    return _buildRow(
      id: 'collections_$parentId',
      title: 'Collections',
      response: response,
      serverId: serverId,
      rowType: HomeRowType.latestMedia,
    );
  }

  Future<HomeRow> loadLibraryLastPlayed(
    String parentId,
    String serverId, {
    List<String>? includeItemTypes,
  }) async {
    final response = await _getItemsWithFallback(
      parentId: parentId,
      sortBy: 'DatePlayed',
      sortOrder: 'Descending',
      filters: ['IsPlayed'],
      recursive: true,
      limit: _defaultLimit,
      includeItemTypes: includeItemTypes,
    );
    return _buildRow(
      id: 'lastPlayed_$parentId',
      title: 'Last Played',
      response: response,
      serverId: serverId,
      rowType: HomeRowType.latestMedia,
    );
  }

  Future<HomeRow> loadLibraryItemsByType(
    String parentId,
    String serverId, {
    required String title,
    required List<String> includeItemTypes,
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
  }) async {
    final isAlbumArtistBrowse =
        includeItemTypes.length == 1 && includeItemTypes.first == 'AlbumArtist';
    final response =
        isAlbumArtistBrowse
            ? await _client.itemsApi.getAlbumArtists(
              parentId: parentId,
              userId: _client.userId,
              sortBy: sortBy,
              sortOrder: sortOrder,
              recursive: true,
              limit: _defaultLimit,
              fields: 'PrimaryImageAspectRatio,SortName',
            )
            : await _getItemsWithFallback(
              parentId: parentId,
              includeItemTypes: includeItemTypes,
              sortBy: sortBy,
              sortOrder: sortOrder,
              recursive: true,
              limit: _defaultLimit,
            );
    return _buildRow(
      id: '${includeItemTypes.first.toLowerCase()}_$parentId',
      title: title,
      response: response,
      serverId: serverId,
      rowType: HomeRowType.latestMedia,
    );
  }

  Future<List<AggregatedItem>> loadMore({
    required HomeRow row,
    required String serverId,
  }) async {
    if (!row.hasMore || row.items.length >= _maxItems) return row.items;

    Map<String, dynamic> response;

    switch (row.rowType) {
      case HomeRowType.playlists:
        response = await _getItemsWithFallback(
          includeItemTypes: ['Playlist'],
          sortBy: 'SortName',
          sortOrder: 'Ascending',
          recursive: true,
          startIndex: row.items.length,
          limit: _defaultLimit,
        );
      case HomeRowType.resume:
      case HomeRowType.resumeAudio:
      case HomeRowType.nextUp:
      case HomeRowType.latestMedia:
      case HomeRowType.libraryTiles:
      case HomeRowType.libraryTilesSmall:
      case HomeRowType.liveTv:
      case HomeRowType.liveTvOnNow:
      case HomeRowType.activeRecordings:
      case HomeRowType.mediaBar:
      case HomeRowType.pluginDynamic:
        return row.items;
    }

    final newItems =
        row.rowType == HomeRowType.playlists
            ? await filterBrowsablePlaylists(
              _client,
              _parseItems(response, serverId),
              mediaType:
                  row.items.isNotEmpty &&
                          row.items.every(isAudioPlaylistSummary)
                      ? 'Audio'
                      : null,
            )
            : _parseItems(response, serverId);
    return [...row.items, ...newItems];
  }

  Future<Map<String, dynamic>> _getItemsWithFallback({
    String? parentId,
    List<String>? includeItemTypes,
    List<String>? filters,
    String? sortBy,
    String? sortOrder,
    bool? recursive,
    int? startIndex,
    int? limit,
    bool? isFavorite,
  }) async {
    try {
      final response = await _client.itemsApi.getItems(
        parentId: parentId,
        includeItemTypes: includeItemTypes,
        filters: filters,
        sortBy: sortBy,
        sortOrder: sortOrder,
        recursive: recursive,
        startIndex: startIndex,
        limit: limit,
        isFavorite: isFavorite,
        fields: _fields,
      );
      return response;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode < 500) rethrow;

      final fallbackSort = (sortBy ?? '').toLowerCase().contains('isfolder')
          ? 'SortName'
          : sortBy;

      final response = await _client.itemsApi.getItems(
        parentId: parentId,
        includeItemTypes: includeItemTypes,
        filters: filters,
        sortBy: fallbackSort,
        sortOrder: sortOrder,
        recursive: recursive,
        startIndex: startIndex,
        limit: limit,
        isFavorite: isFavorite,
        fields: _fallbackFields,
        enableTotalRecordCount: false,
      );
      return response;
    }
  }

  Future<Map<String, dynamic>> _getResumeItemsWithFallback({
    String? parentId,
    List<String>? includeItemTypes,
    required int limit,
  }) async {
    try {
      final response = await _client.itemsApi.getResumeItems(
        parentId: parentId,
        includeItemTypes: includeItemTypes,
        limit: limit,
        fields: _fields,
      ).timeout(const Duration(seconds: 8));
      return response;
    } on TimeoutException {
      final response = await _client.itemsApi.getResumeItems(
        parentId: parentId,
        includeItemTypes: includeItemTypes,
        limit: limit,
        fields: _fallbackFields,
      ).timeout(const Duration(seconds: 6));
      return response;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode < 500) rethrow;
      final response = await _client.itemsApi.getResumeItems(
        parentId: parentId,
        includeItemTypes: includeItemTypes,
        limit: limit,
        fields: _fallbackFields,
      );
      return response;
    }
  }

  Future<Map<String, dynamic>> _getNextUpWithFallback({
    String? parentId,
    required int limit,
    bool? enableResumable,
  }) async {
    try {
      final response = await _client.itemsApi.getNextUp(
        parentId: parentId,
        limit: limit,
        fields: _fields,
        enableResumable: enableResumable,
      ).timeout(const Duration(seconds: 8));
      return response;
    } on TimeoutException {
      final response = await _client.itemsApi.getNextUp(
        parentId: parentId,
        limit: limit,
        fields: _fallbackFields,
        enableResumable: enableResumable,
      ).timeout(const Duration(seconds: 6));
      return response;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode < 500) rethrow;
      final response = await _client.itemsApi.getNextUp(
        parentId: parentId,
        limit: limit,
        fields: _fallbackFields,
        enableResumable: enableResumable,
      );
      return response;
    }
  }

  Future<Map<String, dynamic>> getResumeItemsRelaxed({
    String? parentId,
    List<String>? includeItemTypes,
    required int limit,
  }) async {
    try {
      final response = await _client.itemsApi.getResumeItems(
        parentId: parentId,
        includeItemTypes: includeItemTypes,
        limit: limit,
        fields: _fields,
      ).timeout(const Duration(seconds: 20));
      return response;
    } on TimeoutException {
      try {
        final response = await _client.itemsApi.getResumeItems(
          parentId: parentId,
          includeItemTypes: includeItemTypes,
          limit: limit,
          fields: _minimalFields,
        ).timeout(const Duration(seconds: 12));
        return response;
      } catch (e) {
        return {'Items': []};
      }
    } catch (e) {
      return {'Items': []};
    }
  }

  Future<Map<String, dynamic>> getNextUpRelaxed({
    String? parentId,
    required int limit,
    bool? enableResumable,
  }) async {
    try {
      final response = await _client.itemsApi.getNextUp(
        parentId: parentId,
        limit: limit,
        fields: _fields,
        enableResumable: enableResumable,
      ).timeout(const Duration(seconds: 20));
      return response;
    } on TimeoutException {
      try {
        final response = await _client.itemsApi.getNextUp(
          parentId: parentId,
          limit: limit,
          fields: _minimalFields,
          enableResumable: enableResumable,
        ).timeout(const Duration(seconds: 12));
        return response;
      } catch (e) {
        return {'Items': []};
      }
    } catch (e) {
      return {'Items': []};
    }
  }

  Future<Map<String, dynamic>> _getLatestItemsWithFallback({
    required String parentId,
    required int limit,
  }) async {
    try {
      final response = await _client.itemsApi.getLatestItems(
        parentId: parentId,
        limit: limit,
        fields: _fields,
      );
      return response;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode < 500) rethrow;
      final response = await _client.itemsApi.getLatestItems(
        parentId: parentId,
        limit: limit,
        fields: _fallbackFields,
      );
      return response;
    }
  }

  HomeRow _buildRow({
    required String id,
    required String title,
    required Map<String, dynamic> response,
    required String serverId,
    required HomeRowType rowType,
  }) {
    final items = _parseItems(response, serverId);
    final totalCount = response['TotalRecordCount'] as int? ?? items.length;
    return HomeRow(
      id: id,
      title: title,
      items: items,
      rowType: rowType,
      totalCount: totalCount,
    );
  }

  /// Loads items for a dynamic section provided by the third-party
  /// "Home Screen Sections" Jellyfin plugin. Returns an empty row if the
  /// plugin is not installed/enabled on the active server.
  Future<HomeRow> loadDynamicSection({
    required String rowId,
    required String section,
    required String title,
    required String serverId,
    String? additionalData,
  }) async {
    final api = _client.homeScreenSectionsApi;
    if (api == null) {
      return HomeRow(
        id: rowId,
        title: title,
        rowType: HomeRowType.pluginDynamic,
      );
    }
    try {
      final response = await api.getSectionItems(
        section,
        additionalData: additionalData,
      );
      // The plugin endpoint omits expensive fields like Overview, so re-fetch
      // via /Items to populate the info overlay.
      final enriched = await _enrichItemsWithFields(response);
      return _buildRow(
        id: rowId,
        title: title,
        response: enriched,
        serverId: serverId,
        rowType: HomeRowType.pluginDynamic,
      );
    } catch (_) {
      return HomeRow(
        id: rowId,
        title: title,
        rowType: HomeRowType.pluginDynamic,
      );
    }
  }

  Future<Map<String, dynamic>> _enrichItemsWithFields(
    Map<String, dynamic> response,
  ) async {
    final items = response['Items'];
    if (items is! List || items.isEmpty) return response;
    final ids = <String>[];
    for (final raw in items) {
      if (raw is Map && raw['Id'] is String) {
        ids.add(raw['Id'] as String);
      }
    }
    if (ids.isEmpty) return response;
    try {
      final full = await _client.itemsApi.getItems(
        ids: ids,
        fields: _fields,
        limit: ids.length,
      );
      final fullItems = full['Items'];
      if (fullItems is! List || fullItems.isEmpty) return response;
      final byId = <String, Map<String, dynamic>>{};
      for (final raw in fullItems) {
        if (raw is Map && raw['Id'] is String) {
          byId[raw['Id'] as String] = raw.cast<String, dynamic>();
        }
      }
      final merged = <Map<String, dynamic>>[];
      for (final raw in items) {
        if (raw is Map && raw['Id'] is String) {
          final id = raw['Id'] as String;
          merged.add(byId[id] ?? raw.cast<String, dynamic>());
        } else if (raw is Map) {
          merged.add(raw.cast<String, dynamic>());
        }
      }
      return {
        ...response,
        'Items': merged,
      };
    } catch (_) {
      return response;
    }
  }

  List<AggregatedItem> _parseItems(
    Map<String, dynamic> response,
    String serverId,
  ) {
    final rawItems = response['Items'] as List? ?? [];
    final blocked = _blockedParentalRatings();
    final items = rawItems.map((item) {
      final data = item as Map<String, dynamic>;
      return AggregatedItem(
        id: data['Id'] as String,
        serverId: serverId,
        rawData: data,
      );
    });
    if (blocked.isEmpty) return items.toList();
    return items.where((item) {
      final rating = item.officialRating?.trim().toUpperCase();
      if (rating == null || rating.isEmpty) return true;
      return !blocked.contains(rating);
    }).toList();
  }

  Set<String> _blockedParentalRatings() {
    if (!GetIt.instance.isRegistered<UserPreferences>()) return const {};
    final csv = GetIt.instance<UserPreferences>()
        .get(UserPreferences.blockedParentalRatings);
    if (csv.trim().isEmpty) return const {};
    return csv
        .split(',')
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet();
  }
}
