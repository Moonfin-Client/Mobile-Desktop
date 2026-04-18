import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:server_core/server_core.dart';

class MdbListRepository {
  static const _maxCacheEntries = 64;

  final MediaServerClient _client;
  final _dio = Dio();

  final _cache = <String, Map<String, double>>{};
  final _pending = <String, Completer<Map<String, double>?>>{};
  bool _endpointUnavailable = false;

  MdbListRepository(this._client);

  Future<Map<String, double>?> getRatings({
    required String tmdbId,
    required String mediaType,
  }) async {
    if (_endpointUnavailable) return null;

    final type = switch (mediaType) {
      'Movie' => 'movie',
      'Series' || 'Season' || 'Episode' => 'show',
      _ => 'movie',
    };

    final cacheKey = '$type:$tmdbId';

    final cached = _takeCached(cacheKey);
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
      _storeCacheEntry(cacheKey, result);
      completer.complete(result);
      _pending.remove(cacheKey);
      return result;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 404) {
        _endpointUnavailable = true;
        debugPrint(
          '[Moonfin] MdbList endpoint unavailable (404). Disabling MDBList requests for this session.',
        );
      } else {
        debugPrint('[Moonfin] MdbList fetch failed: $e');
      }
      completer.complete(null);
      _pending.remove(cacheKey);
      return null;
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
    _endpointUnavailable = false;
  }

  void dispose() {
    clearCache();
    _dio.close(force: true);
  }

  Map<String, double>? _takeCached(String cacheKey) {
    final cached = _cache.remove(cacheKey);
    if (cached != null) {
      _cache[cacheKey] = cached;
    }
    return cached;
  }

  void _storeCacheEntry(String cacheKey, Map<String, double> result) {
    _cache.remove(cacheKey);
    _cache[cacheKey] = result;
    while (_cache.length > _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
  }
}
