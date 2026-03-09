import 'package:server_core/server_core.dart';

import '../models/aggregated_item.dart';
import '../models/home_row.dart';

class RowDataSource {
  final MediaServerClient _client;

  static const _defaultLimit = 15;
  static const _maxItems = 100;

  static const _fields =
      'PrimaryImageAspectRatio,BasicSyncInfo,Overview,Genres,CommunityRating,'
      'OfficialRating,RunTimeTicks,ProductionYear,SeriesName,ParentIndexNumber,'
      'IndexNumber,Status,ImageTags,BackdropImageTags,ParentBackdropItemId,'
      'ParentBackdropImageTags';

  RowDataSource(this._client);

  ImageApi get imageApi => _client.imageApi;

  Future<HomeRow> loadResume(String serverId) async {
    final response = await _client.itemsApi.getResumeItems(
      includeItemTypes: ['Video'],
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
    final response = await _client.itemsApi.getResumeItems(
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
    final response = await _client.itemsApi.getNextUp(limit: _defaultLimit);
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
    String serverId,
  ) async {
    final response = await _client.itemsApi.getLatestItems(
      parentId: parentId,
      limit: _defaultLimit,
    );
    return _buildRow(
      id: 'latest_$parentId',
      title: 'Latest $libraryName',
      response: response,
      serverId: serverId,
      rowType: HomeRowType.latestMedia,
    );
  }

  Future<HomeRow> loadPlaylists(String serverId) async {
    final response = await _client.itemsApi.getItems(
      includeItemTypes: ['Playlist'],
      sortBy: 'SortName',
      sortOrder: 'Ascending',
      recursive: true,
      limit: _defaultLimit,
      fields: _fields,
    );
    return _buildRow(
      id: 'playlists',
      title: 'Playlists',
      response: response,
      serverId: serverId,
      rowType: HomeRowType.playlists,
    );
  }

  Future<HomeRow> loadLibraryTiles(String serverId) async {
    final response = await _client.userViewsApi.getUserViews();
    return _buildRow(
      id: 'libraryTiles',
      title: 'My Libraries',
      response: response,
      serverId: serverId,
      rowType: HomeRowType.libraryTiles,
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
        response = await _client.itemsApi.getItems(
          includeItemTypes: ['Playlist'],
          sortBy: 'SortName',
          sortOrder: 'Ascending',
          recursive: true,
          startIndex: row.items.length,
          limit: _defaultLimit,
          fields: _fields,
        );
      case HomeRowType.resume:
      case HomeRowType.resumeAudio:
      case HomeRowType.nextUp:
      case HomeRowType.latestMedia:
      case HomeRowType.libraryTiles:
      case HomeRowType.liveTv:
      case HomeRowType.activeRecordings:
      case HomeRowType.mediaBar:
        return row.items;
    }

    final newItems = _parseItems(response, serverId);
    return [...row.items, ...newItems];
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

  List<AggregatedItem> _parseItems(
    Map<String, dynamic> response,
    String serverId,
  ) {
    final rawItems = response['Items'] as List? ?? [];
    return rawItems.map((item) {
      final data = item as Map<String, dynamic>;
      return AggregatedItem(
        id: data['Id'] as String,
        serverId: serverId,
        rawData: data,
      );
    }).toList();
  }
}
