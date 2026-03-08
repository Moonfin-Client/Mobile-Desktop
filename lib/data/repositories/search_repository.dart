import 'package:server_core/server_core.dart';

import '../models/aggregated_item.dart';

class SearchRepository {
  final MediaServerClient _client;

  SearchRepository(this._client);

  Future<List<AggregatedItem>> search(
    String query, {
    List<String>? includeItemTypes,
    int? limit,
  }) async {
    final response = await _client.itemsApi.getItems(
      searchTerm: query,
      includeItemTypes: includeItemTypes,
      limit: limit ?? 24,
      recursive: true,
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
