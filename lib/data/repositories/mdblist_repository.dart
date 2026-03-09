import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:server_core/server_core.dart';

class MdbListRepository {
  final MediaServerClient _client;
  final _dio = Dio();

  final _cache = <String, Map<String, double>>{};
  final _pending = <String, Completer<Map<String, double>?>>{};

  MdbListRepository(this._client);

  Future<Map<String, double>?> getRatings({
    required String tmdbId,
    required String mediaType,
  }) async {
    final type = switch (mediaType) {
      'Movie' => 'movie',
      'Series' || 'Season' || 'Episode' => 'show',
      _ => 'movie',
    };

    final cacheKey = '$type:$tmdbId';

    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final existing = _pending[cacheKey];
    if (existing != null) return existing.future;

    final completer = Completer<Map<String, double>?>();
    _pending[cacheKey] = completer;

    try {
      final baseUrl = _client.baseUrl;
      final token = _client.accessToken;
      if (token == null) {
        completer.complete(null);
        _pending.remove(cacheKey);
        return null;
      }

      final response = await _dio.get(
        '$baseUrl/Moonfin/MdbList/Ratings',
        queryParameters: {'type': type, 'tmdbId': tmdbId},
        options: Options(headers: {
          'Authorization': 'MediaBrowser Token="$token"',
        }),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        completer.complete(null);
        _pending.remove(cacheKey);
        return null;
      }

      final success = data['success'] as bool? ?? false;
      if (!success || data['error'] != null) {
        completer.complete(null);
        _pending.remove(cacheKey);
        return null;
      }

      final ratings = (data['ratings'] as List?)
          ?.cast<Map<String, dynamic>>()
          .where((r) => r['source'] != null)
          .map((r) {
            final source = (r['source'] as String).toLowerCase();
            final value = switch (source) {
              'metacriticuser' =>
                (r['score'] as num?)?.toDouble() ??
                (r['value'] as num?)?.toDouble(),
              _ =>
                (r['value'] as num?)?.toDouble() ??
                (r['score'] as num?)?.toDouble(),
            };
            if (value == null || value <= 0) return null;
            return MapEntry(source, value);
          })
          .whereType<MapEntry<String, double>>();

      final result = Map<String, double>.fromEntries(ratings ?? []);
      _cache[cacheKey] = result;
      completer.complete(result);
      _pending.remove(cacheKey);
      return result;
    } catch (e) {
      debugPrint('[Moonfin] MdbList fetch failed: $e');
      completer.complete(null);
      _pending.remove(cacheKey);
      return null;
    }
  }

  void clearCache() {
    _cache.clear();
    _pending.clear();
  }
}
