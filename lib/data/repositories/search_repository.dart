import 'package:server_core/server_core.dart';

import '../models/aggregated_item.dart';

class SearchRepository {
  final MediaServerClient _client;

  static const _searchFields =
      'Type,UserData,ProductionYear,SeriesName,ParentIndexNumber,IndexNumber,'
      'AlbumArtist,Album,ImageTags,BackdropImageTags,ParentBackdropItemId,'
      'ParentBackdropImageTags,SeriesId,SeriesPrimaryImageTag';

  SearchRepository(this._client);

  Future<List<AggregatedItem>> search(
    String query, {
    List<String>? includeItemTypes,
    String? parentId,
    int? limit,
  }) async {
    final response = await _client.itemsApi.getItems(
      searchTerm: query,
      parentId: parentId,
      includeItemTypes: includeItemTypes,
      limit: limit ?? 24,
      recursive: true,
      fields: _searchFields,
    );

    final items = response['Items'] as List? ?? [];
    return items.map((item) {
      final data = item as Map<String, dynamic>;
      return AggregatedItem(
        id: data['Id'] as String,
        serverId: data['ServerId'] as String? ?? '',
        rawData: data,
      );
    }).toList();
  }
}
