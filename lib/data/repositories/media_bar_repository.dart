import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:server_core/server_core.dart';

import '../../preference/user_preferences.dart';
import '../models/media_bar_slide_item.dart';
import '../models/media_bar_state.dart';

class MediaBarRepository {
  static const _precacheBackdropCount = 4;
  static const _precacheLogoCount = 2;

  final MediaServerClient _client;
  final UserPreferences _prefs;

  static const _fields =
      'Type,Genres,OfficialRating,CommunityRating,CriticRating,'
      'RunTimeTicks,ProductionYear,ImageTags,BackdropImageTags,'
      'Overview,ProviderIds';

  MediaBarRepository(this._client, this._prefs);

  Future<MediaBarState> loadItems() async {
    if (!_prefs.get(UserPreferences.mediaBarEnabled)) {
      return const MediaBarDisabled();
    }

    try {
      final contentType = _prefs.get(UserPreferences.mediaBarContentType);
      final maxItems =
          int.tryParse(_prefs.get(UserPreferences.mediaBarItemCount)) ?? 10;
      final libraryIds = _prefs
          .get(UserPreferences.mediaBarLibraryIds)
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList();
      final collectionIds = _prefs
          .get(UserPreferences.mediaBarCollectionIds)
          .split(',')
          .where((s) => s.isNotEmpty)
          .toList();
      final excludedGenres = _prefs
          .get(UserPreferences.mediaBarExcludedGenres)
          .split(',')
          .where((s) => s.isNotEmpty)
          .toSet();

      final allItems = <Map<String, dynamic>>[];
      final fetchLimit = maxItems + 2;

      final includeTypes = switch (contentType) {
        'movies' => const ['Movie'],
        'tvshows' => const ['Series'],
        _ => const ['Movie', 'Series'],
      };

      final fetchTasks = <Future<List<Map<String, dynamic>>>>[];

      if (libraryIds.isEmpty) {
        fetchTasks.add(_fetchItems(includeTypes, fetchLimit));
      } else {
        for (final libraryId in libraryIds) {
          fetchTasks.add(_fetchItems(includeTypes, fetchLimit, parentId: libraryId));
        }
      }

      for (final collectionId in collectionIds) {
        fetchTasks.add(_fetchItems(includeTypes, fetchLimit, parentId: collectionId));
      }

      final fetchedBatches = await Future.wait(fetchTasks);
      for (final batch in fetchedBatches) {
        allItems.addAll(batch);
      }

      var withBackdrops = allItems
          .where((item) =>
              _hasBackdrop(item) &&
              !_isBoxSet(item) &&
              !_hasExcludedGenre(item, excludedGenres))
          .toList()
        ..shuffle();

      var selected = withBackdrops.take(maxItems).toList();

      if (selected.isEmpty && (libraryIds.isNotEmpty || collectionIds.isNotEmpty)) {
        final fallbackItems = <Map<String, dynamic>>[];
        fallbackItems.addAll(await _fetchItems(includeTypes, fetchLimit));

        withBackdrops = fallbackItems
            .where((item) =>
                _hasBackdrop(item) &&
                !_isBoxSet(item) &&
                !_hasExcludedGenre(item, excludedGenres))
            .toList()
          ..shuffle();
        selected = withBackdrops.take(maxItems).toList();
      }

      if (selected.isEmpty) {
        return const MediaBarError('No items with backdrop images found');
      }

      final items = selected.map(_toSlideItem).toList();
      return MediaBarReady(items);
    } catch (e) {
      return MediaBarError('Failed to load: $e');
    }
  }

  void precacheImages(BuildContext context, List<MediaBarSlideItem> items) {
    for (final item in items.take(_precacheBackdropCount)) {
      if (item.backdropUrl != null) {
        precacheImage(CachedNetworkImageProvider(item.backdropUrl!), context);
      }
    }
    for (final item in items.take(_precacheLogoCount)) {
      if (item.logoUrl != null) {
        precacheImage(CachedNetworkImageProvider(item.logoUrl!), context);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchItems(
    List<String>? itemTypes,
    int limit, {
    String? parentId,
  }) async {
    try {
      final response = await _client.itemsApi.getItems(
        includeItemTypes: itemTypes,
        sortBy: 'Random',
        sortOrder: 'Descending',
        recursive: true,
        parentId: parentId,
        limit: limit,
        fields: _fields,
        enableTotalRecordCount: false,
        enableImageTypes: 'Backdrop,Logo',
      ).timeout(const Duration(seconds: 3));
      final rawItems = response['Items'] as List? ?? [];
      return rawItems.cast<Map<String, dynamic>>();
    } on TimeoutException {
      return _fetchItemsFromFallbackSource(itemTypes, limit, parentId: parentId);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 0;
      if (statusCode == 401 || statusCode == 403) {
        return const <Map<String, dynamic>>[];
      }
      if (statusCode != 400 && statusCode < 500) {
        rethrow;
      }

      return _fetchItemsFromFallbackSource(itemTypes, limit, parentId: parentId);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchItemsFromFallbackSource(
    List<String>? itemTypes,
    int limit, {
    String? parentId,
  }) async {
    final reducedLimit = limit > 24 ? 24 : limit;

    try {
      final latestResponse = await _client.itemsApi.getLatestItems(
        includeItemTypes: itemTypes,
        parentId: parentId,
        limit: reducedLimit,
        fields: _fields,
      ).timeout(const Duration(seconds: 4));
      final rawItems = latestResponse['Items'] as List? ?? [];
      return rawItems.cast<Map<String, dynamic>>();
    } catch (_) {}

    try {
      final fallbackResponse = await _client.itemsApi.getItems(
        includeItemTypes: itemTypes,
        sortBy: 'SortName',
        sortOrder: 'Ascending',
        recursive: true,
        parentId: parentId,
        limit: reducedLimit,
        fields: _fields,
        enableTotalRecordCount: false,
        enableImageTypes: 'Backdrop,Logo',
      ).timeout(const Duration(seconds: 4));
      final rawItems = fallbackResponse['Items'] as List? ?? [];
      return rawItems.cast<Map<String, dynamic>>();
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  bool _hasBackdrop(Map<String, dynamic> item) {
    final tags = item['BackdropImageTags'] as List?;
    return tags != null && tags.isNotEmpty;
  }

  bool _isBoxSet(Map<String, dynamic> item) {
    return item['Type'] == 'BoxSet';
  }

  bool _hasExcludedGenre(Map<String, dynamic> item, Set<String> excluded) {
    if (excluded.isEmpty) return false;
    final genres = (item['Genres'] as List?)?.cast<String>() ?? [];
    return genres.any((g) => excluded.contains(g));
  }

  MediaBarSlideItem _toSlideItem(Map<String, dynamic> data) {
    final itemId = data['Id'] as String;
    final serverId = data['ServerId'] as String? ?? '';
    final providerIds = data['ProviderIds'] as Map<String, dynamic>?;

    final backdropTags = data['BackdropImageTags'] as List?;
    final backdropUrl = (backdropTags != null && backdropTags.isNotEmpty)
      ? _client.imageApi.getBackdropImageUrl(itemId, tag: backdropTags[0] as String)
        : null;

    final logoTag = (data['ImageTags'] as Map?)?['Logo'] as String?;
    final logoUrl = logoTag != null
      ? _client.imageApi.getLogoImageUrl(itemId, tag: logoTag, maxWidth: 600)
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
      remoteTrailers: (data['RemoteTrailers'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          const [],
    );
  }
}
