import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

class JellyfinAdminItemsApi implements AdminItemsApi {
  final Dio _dio;

  JellyfinAdminItemsApi(this._dio);

  @override
  Future<void> updateItem(String itemId, Map<String, dynamic> itemData) async {
    await _requestWithFallback<void>(
      methods: const ['POST', 'PUT'],
      paths: ['/Items/$itemId'],
      data: itemData,
      convert: (_) => null,
    );
  }

  @override
  Future<Map<String, dynamic>> getMetadataEditor(String itemId) async {
    return _requestWithFallback<Map<String, dynamic>>(
      methods: const ['GET'],
      paths: ['/Items/$itemId/MetadataEditor'],
      convert: (data) {
        if (data is Map<String, dynamic>) return data;
        return const {};
      },
    );
  }

  @override
  Future<void> updateContentType(String itemId, String contentType) async {
    await _requestWithFallback<void>(
      methods: const ['POST'],
      paths: ['/Items/$itemId/ContentType'],
      queryParameters: {'ContentType': contentType},
      convert: (_) => null,
    );
  }

  @override
  Future<void> refreshItem(
    String itemId, {
    bool? recursive,
    bool? replaceAllMetadata,
    bool? replaceAllImages,
  }) async {
    await _requestWithFallback<void>(
      methods: const ['POST'],
      paths: ['/Items/$itemId/Refresh'],
      queryParameters: {
        if (recursive != null) 'Recursive': recursive,
        if (replaceAllMetadata != null)
          'ReplaceAllMetadata': replaceAllMetadata,
        if (replaceAllImages != null) 'ReplaceAllImages': replaceAllImages,
      },
      convert: (_) => null,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getExternalIdInfos(String itemId) async {
    return _requestWithFallback<List<Map<String, dynamic>>>(
      methods: const ['GET'],
      paths: [
        '/Items/$itemId/ExternalIdInfos',
        '/Items/$itemId/ExternalIds',
      ],
      convert: _asList,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> searchRemotePerson(
    Map<String, dynamic> query,
  ) async {
    return _requestWithFallback<List<Map<String, dynamic>>>(
      methods: const ['POST'],
      paths: ['/Items/RemoteSearch/Person'],
      data: query,
      convert: _asList,
    );
  }

  @override
  Future<void> applyRemoteSearchResult(
    String itemId,
    Map<String, dynamic> result,
  ) async {
    await _requestWithFallback<void>(
      methods: const ['POST'],
      paths: [
        '/Items/RemoteSearch/Apply/$itemId',
        '/Items/$itemId/RemoteSearch/Apply',
      ],
      data: result,
      convert: (_) => null,
    );
  }

  @override
  Future<Map<String, dynamic>> getRemoteImages(
    String itemId, {
    required ImageType imageType,
    int? startIndex,
    int? limit,
    String? providerName,
    bool? includeAllLanguages,
  }) async {
    return _requestWithFallback<Map<String, dynamic>>(
      methods: const ['GET'],
      paths: ['/Items/$itemId/RemoteImages'],
      queryParameters: {
        'Type': imageType.toServerString(),
        if (startIndex != null) 'StartIndex': startIndex,
        if (limit != null) 'Limit': limit,
        if (providerName != null && providerName.isNotEmpty)
          'ProviderName': providerName,
        if (includeAllLanguages != null)
          'IncludeAllLanguages': includeAllLanguages,
      },
      convert: (data) {
        if (data is Map<String, dynamic>) {
          return {
            'Images': _asList(data['Images']),
            'Providers': (data['Providers'] is List)
                ? (data['Providers'] as List)
                    .map((entry) => entry.toString())
                    .where((entry) => entry.isNotEmpty)
                    .toList()
                : const <String>[],
            'TotalRecordCount': data['TotalRecordCount'] ?? 0,
          };
        }
        return const {
          'Images': <Map<String, dynamic>>[],
          'Providers': <String>[],
          'TotalRecordCount': 0,
        };
      },
    );
  }

  @override
  Future<void> downloadRemoteImage(
    String itemId, {
    required ImageType imageType,
    required String imageUrl,
  }) async {
    await _requestWithFallback<void>(
      methods: const ['POST'],
      paths: ['/Items/$itemId/RemoteImages/Download'],
      queryParameters: {
        'Type': imageType.toServerString(),
        'ImageUrl': imageUrl,
      },
      convert: (_) => null,
    );
  }

  @override
  Future<void> uploadItemImage(
    String itemId, {
    required ImageType imageType,
    required List<int> bytes,
    required String contentType,
  }) async {
    await _dio.post(
      '/Items/$itemId/Images/${imageType.toServerString()}',
      data: base64Encode(bytes),
      options: Options(contentType: contentType),
    );
  }

  @override
  Future<void> deleteItemImage(
    String itemId, {
    required ImageType imageType,
    int? imageIndex,
  }) async {
    await _dio.delete(
      '/Items/$itemId/Images/${imageType.toServerString()}',
      queryParameters: {
        if (imageIndex != null) 'ImageIndex': imageIndex,
      },
    );
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    if (data is Map<String, dynamic>) {
      final items =
          data['Items'] ?? data['items'] ?? data['Results'] ?? data['results'];
      if (items is List) {
        return items
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
    }
    return const [];
  }

  Future<T> _requestWithFallback<T>({
    required List<String> methods,
    required List<String> paths,
    Map<String, dynamic>? queryParameters,
    Object? data,
    required T Function(dynamic data) convert,
  }) async {
    DioException? lastDioError;

    for (final path in paths) {
      for (final method in methods) {
        try {
          final response = switch (method) {
            'GET' => await _dio.get(path, queryParameters: queryParameters),
            'POST' => await _dio.post(
                path,
                queryParameters: queryParameters,
                data: data,
              ),
            'PUT' => await _dio.put(
                path,
                queryParameters: queryParameters,
                data: data,
              ),
            _ => throw ArgumentError('Unknown HTTP method: $method'),
          };
          return convert(response.data);
        } on DioException catch (e) {
          final status = e.response?.statusCode;
          if (status == 404 || status == 405 || status == 501) {
            lastDioError = e;
            continue;
          }
          rethrow;
        }
      }
    }

    throw lastDioError ?? StateError('No admin item endpoint responded');
  }
}
