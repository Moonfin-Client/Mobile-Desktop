import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

class JellyfinHomeScreenSectionsApi implements HomeScreenSectionsApi {
  final Dio _dio;
  final String? Function() _userIdProvider;

  JellyfinHomeScreenSectionsApi(this._dio, this._userIdProvider);

  @override
  Future<HomeScreenMeta> getMeta() async {
    final response = await _dio.get('/HomeScreen/Meta');
    final data = response.data;
    if (data is Map) {
      return HomeScreenMeta.fromJson(data.cast<String, dynamic>());
    }
    return const HomeScreenMeta();
  }

  @override
  Future<List<HomeScreenSectionInfo>> getUserSections() async {
    final params = <String, dynamic>{};
    final userId = _userIdProvider();
    if (userId != null) params['userId'] = userId;

    final response = await _dio.get(
      '/HomeScreen/Sections',
      queryParameters: params.isEmpty ? null : params,
    );
    final data = response.data;
    Iterable rawItems = const [];
    if (data is Map) {
      final items = data['Items'];
      if (items is List) rawItems = items;
    } else if (data is List) {
      rawItems = data;
    }
    return rawItems
        .whereType<Map>()
        .map((m) => HomeScreenSectionInfo.fromJson(m.cast<String, dynamic>()))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> getSectionItems(
    String sectionType, {
    String? additionalData,
  }) async {
    final userId = _userIdProvider();
    if (userId == null) {
      throw StateError('userId not configured');
    }
    final params = <String, dynamic>{'userId': userId};
    if (additionalData != null && additionalData.isNotEmpty) {
      params['additionalData'] = additionalData;
    }
    final encoded = Uri.encodeComponent(sectionType);
    final response = await _dio.get(
      '/HomeScreen/Section/$encoded',
      queryParameters: params,
    );
    final data = response.data;
    if (data is Map) return data.cast<String, dynamic>();
    return const {};
  }
}
