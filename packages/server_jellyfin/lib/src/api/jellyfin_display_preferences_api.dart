import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

class JellyfinDisplayPreferencesApi implements DisplayPreferencesApi {
  final Dio _dio;

  JellyfinDisplayPreferencesApi(this._dio);

  @override
  Future<DisplayPreferences> getDisplayPreferences(
    String id, {
    String? client,
  }) async {
    final response =
        await _dio.get('/DisplayPreferences/$id', queryParameters: {
      'client': client ?? 'moonfin',
    });
    return DisplayPreferences.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> saveDisplayPreferences(
    String id,
    DisplayPreferences prefs, {
    String? client,
  }) async {
    await _dio.post(
      '/DisplayPreferences/$id',
      data: prefs.toJson(),
      queryParameters: {
        'client': client ?? 'moonfin',
      },
    );
  }
}
