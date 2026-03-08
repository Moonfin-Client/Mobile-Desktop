import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

class EmbyInstantMixApi implements InstantMixApi {
  final Dio _dio;

  EmbyInstantMixApi(this._dio);

  @override
  Future<Map<String, dynamic>> getInstantMix(
    String itemId, {
    int? limit,
  }) async {
    final response = await _dio.get(
      '/Items/$itemId/InstantMix',
      queryParameters: {
        if (limit != null) 'Limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }
}
