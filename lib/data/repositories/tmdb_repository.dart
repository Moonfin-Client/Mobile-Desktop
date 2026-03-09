import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:server_core/server_core.dart';

class TmdbRepository {
  final MediaServerClient _client;

  final _dio = Dio();

  final _episodeCache = <String, double>{};
  final _seasonCache = <String, Map<int, double>>{};
  final _pendingEpisodes = <String, Completer<double?>>{};
  final _pendingSeasons = <String, Completer<Map<int, double>?>>{};

  TmdbRepository(this._client);

  Future<double?> getEpisodeRating({
    required String tmdbId,
    required int season,
    required int episode,
  }) async {
    final cacheKey = '$tmdbId:$season:$episode';

    final cached = _episodeCache[cacheKey];
    if (cached != null) return cached;

    final existing = _pendingEpisodes[cacheKey];
    if (existing != null) return existing.future;

    final completer = Completer<double?>();
    _pendingEpisodes[cacheKey] = completer;

    try {
      final response = await _get('/Moonfin/Tmdb/EpisodeRating', {
        'tmdbId': tmdbId,
        'season': season,
        'episode': episode,
      });

      if (response == null) {
        completer.complete(null);
        _pendingEpisodes.remove(cacheKey);
        return null;
      }

      final rating = (response['voteAverage'] as num?)?.toDouble();
      if (rating != null && rating > 0) {
        _episodeCache[cacheKey] = rating;
        completer.complete(rating);
      } else {
        completer.complete(null);
      }
      _pendingEpisodes.remove(cacheKey);
      return rating != null && rating > 0 ? rating : null;
    } catch (e) {
      debugPrint('[Moonfin] TMDB episode rating fetch failed: $e');
      completer.complete(null);
      _pendingEpisodes.remove(cacheKey);
      return null;
    }
  }

  Future<Map<int, double>?> getSeasonRatings({
    required String tmdbId,
    required int season,
  }) async {
    final cacheKey = '$tmdbId:$season';

    final cached = _seasonCache[cacheKey];
    if (cached != null) return cached;

    final existing = _pendingSeasons[cacheKey];
    if (existing != null) return existing.future;

    final completer = Completer<Map<int, double>?>();
    _pendingSeasons[cacheKey] = completer;

    try {
      final response = await _get('/Moonfin/Tmdb/SeasonRatings', {
        'tmdbId': tmdbId,
        'season': season,
      });

      if (response == null) {
        completer.complete(null);
        _pendingSeasons.remove(cacheKey);
        return null;
      }

      final episodes = response['episodes'] as List?;
      if (episodes == null) {
        completer.complete(null);
        _pendingSeasons.remove(cacheKey);
        return null;
      }

      final result = <int, double>{};
      for (final ep in episodes.cast<Map<String, dynamic>>()) {
        final epNum = ep['episodeNumber'] as int?;
        final rating = (ep['voteAverage'] as num?)?.toDouble();
        if (epNum != null && rating != null && rating > 0) {
          result[epNum] = rating;
          _episodeCache['$tmdbId:$season:$epNum'] = rating;
        }
      }

      _seasonCache[cacheKey] = result;
      completer.complete(result);
      _pendingSeasons.remove(cacheKey);
      return result;
    } catch (e) {
      debugPrint('[Moonfin] TMDB season ratings fetch failed: $e');
      completer.complete(null);
      _pendingSeasons.remove(cacheKey);
      return null;
    }
  }

  Future<Map<String, dynamic>?> _get(
    String path,
    Map<String, dynamic> query,
  ) async {
    final token = _client.accessToken;
    if (token == null) return null;

    final response = await _dio.get(
      '${_client.baseUrl}$path',
      queryParameters: query,
      options: Options(headers: {
        'Authorization': 'MediaBrowser Token="$token"',
      }),
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) return null;

    final success = data['success'] as bool? ?? false;
    if (!success || data['error'] != null) return null;

    return data;
  }

  void clearCache() {
    _episodeCache.clear();
    _seasonCache.clear();
    _pendingEpisodes.clear();
    _pendingSeasons.clear();
  }
}
