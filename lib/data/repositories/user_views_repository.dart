import 'package:server_core/server_core.dart';

import '../models/aggregated_library.dart';

class UserViewsRepository {
  final MediaServerClient _client;

  UserViewsRepository(this._client);

  Future<List<AggregatedLibrary>> getUserViews() async {
    final response = await _client.userViewsApi.getUserViews();
    final items = response['Items'] as List? ?? [];

    return items.map((item) {
      final data = item as Map<String, dynamic>;
      return AggregatedLibrary(
        id: data['Id'] as String,
        name: data['Name'] as String,
        collectionType: data['CollectionType'] as String? ?? '',
        serverId: data['ServerId'] as String? ?? '',
      );
    }).toList();
  }
}
