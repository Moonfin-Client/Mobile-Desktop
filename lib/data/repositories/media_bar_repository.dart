import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:server_core/server_core.dart';

import '../../preference/user_preferences.dart';
import '../models/media_bar_slide_item.dart';
import '../models/media_bar_state.dart';

class MediaBarRepository {
  final MediaServerClient _client;
  final UserPreferences _prefs;

  static const _fields =
      'Overview,Genres,OfficialRating,CommunityRating,CriticRating,'
      'RunTimeTicks,ProductionYear,ProviderIds,ImageTags,BackdropImageTags';

  MediaBarRepository(this._client, this._prefs);

  Future<MediaBarState> loadItems() async {
    if (!_prefs.get(UserPreferences.mediaBarEnabled)) {
      return const MediaBarDisabled();
    }

    try {
      final contentType = _prefs.get(UserPreferences.mediaBarContentType);
      final maxItems =
          int.tryParse(_prefs.get(UserPreferences.mediaBarItemCount)) ?? 10;

      final allItems = <Map<String, dynamic>>[];

      switch (contentType) {
        case 'movies':
          allItems.addAll(await _fetchItems('Movie', maxItems));
        case 'tvshows':
          allItems.addAll(await _fetchItems('Series', maxItems));
        default:
          final half = (maxItems / 2).ceil();
          final results = await Future.wait([
            _fetchItems('Movie', half),
            _fetchItems('Series', half),
          ]);
          allItems.addAll(results.expand((r) => r));
      }

      final withBackdrops = allItems.where(_hasBackdrop).toList()..shuffle();
      final selected = withBackdrops.take(maxItems).toList();

      if (selected.isEmpty) {
        return const MediaBarError('No items with backdrop images found');
      }

      final items = selected.map(_toSlideItem).toList();
      return MediaBarReady(items);
    } catch (e) {
      debugPrint('[Moonfin] MediaBar load failed: $e');
      return MediaBarError('Failed to load: $e');
    }
  }

  void precacheImages(BuildContext context, List<MediaBarSlideItem> items) {
    for (final item in items) {
      if (item.backdropUrl != null) {
        precacheImage(CachedNetworkImageProvider(item.backdropUrl!), context);
      }
      if (item.logoUrl != null) {
        precacheImage(CachedNetworkImageProvider(item.logoUrl!), context);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchItems(
    String itemType,
    int limit,
  ) async {
    final response = await _client.itemsApi.getItems(
      includeItemTypes: [itemType],
      sortBy: 'Random',
      sortOrder: 'Descending',
      recursive: true,
      limit: limit,
      fields: _fields,
    );
    final rawItems = response['Items'] as List? ?? [];
    return rawItems.cast<Map<String, dynamic>>();
  }

  bool _hasBackdrop(Map<String, dynamic> item) {
    final tags = item['BackdropImageTags'] as List?;
    return tags != null && tags.isNotEmpty;
  }

  MediaBarSlideItem _toSlideItem(Map<String, dynamic> data) {
    final itemId = data['Id'] as String;
    final serverId = data['ServerId'] as String? ?? '';
    final providerIds = data['ProviderIds'] as Map<String, dynamic>?;

    final backdropTags = data['BackdropImageTags'] as List?;
    final backdropUrl = (backdropTags != null && backdropTags.isNotEmpty)
        ? _client.imageApi.getBackdropImageUrl(itemId, maxWidth: 1920, tag: backdropTags[0] as String)
        : null;

    final logoTag = (data['ImageTags'] as Map?)?['Logo'] as String?;
    final logoUrl = logoTag != null
        ? _client.imageApi.getLogoImageUrl(itemId, maxWidth: 800, tag: logoTag)
        : null;

    final runTimeTicks = data['RunTimeTicks'] as int?;

    return MediaBarSlideItem(
      itemId: itemId,
      serverId: serverId,
      title: data['Name'] as String? ?? '',
      overview: data['Overview'] as String?,
      backdropUrl: backdropUrl,
      logoUrl: logoUrl,
      officialRating: data['OfficialRating'] as String?,
      year: data['ProductionYear'] as int?,
      genres: (data['Genres'] as List?)?.cast<String>().take(3).toList() ?? const [],
      runtime: runTimeTicks != null ? Duration(microseconds: runTimeTicks ~/ 10) : null,
      communityRating: (data['CommunityRating'] as num?)?.toDouble(),
      criticRating: (data['CriticRating'] as num?)?.toInt(),
      tmdbId: providerIds?['Tmdb'] as String?,
      imdbId: providerIds?['Imdb'] as String?,
      itemType: data['Type'] as String? ?? 'Movie',
    );
  }
}
