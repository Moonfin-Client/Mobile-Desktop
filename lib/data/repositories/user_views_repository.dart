import 'package:server_core/server_core.dart';

import '../models/aggregated_library.dart';

class UserViewsRepository {
  final MediaServerClient _client;
  UserConfiguration? _cachedConfig;

  UserViewsRepository(this._client);

  Future<List<AggregatedLibrary>> getAllViews() async {
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

  Future<List<AggregatedLibrary>> getUserViews() async {
    final views = await getAllViews();
    try {
      final config = await _getUserConfig();
      final excludes = config.myMediaExcludes.toSet();
      if (excludes.isEmpty) return views;
      return views.where((v) => !excludes.contains(v.id)).toList();
    } catch (_) {
      return views;
    }
  }

  Future<UserConfiguration> _getUserConfig() async {
    _cachedConfig ??= await _client.usersApi.getUserConfiguration();
    return _cachedConfig!;
  }

  Future<UserConfiguration> getUserConfiguration() async {
    _cachedConfig = await _client.usersApi.getUserConfiguration();
    return _cachedConfig!;
  }

  Future<void> updateUserConfiguration(UserConfiguration config) async {
    await _client.usersApi.updateUserConfiguration(config);
    _cachedConfig = config;
  }

  void invalidateConfigCache() => _cachedConfig = null;
}
