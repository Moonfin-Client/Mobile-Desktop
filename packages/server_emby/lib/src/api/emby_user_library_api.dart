import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';

class EmbyUserLibraryApi implements UserLibraryApi {
  final Dio _dio;
  final String Function() _getUserId;

  EmbyUserLibraryApi(this._dio, this._getUserId);

  @override
  Future<void> markFavorite(String itemId) async {
    final userId = _getUserId();
    await _dio.post('/Users/$userId/FavoriteItems/$itemId');
  }

  @override
  Future<void> unmarkFavorite(String itemId) async {
    final userId = _getUserId();
    await _dio.delete('/Users/$userId/FavoriteItems/$itemId');
  }

  @override
  Future<void> markPlayed(String itemId) async {
    final userId = _getUserId();
    await _dio.post('/Users/$userId/PlayedItems/$itemId');
  }

  @override
  Future<void> unmarkPlayed(String itemId) async {
    final userId = _getUserId();
    await _dio.delete('/Users/$userId/PlayedItems/$itemId');
  }

  @override
  Future<void> updateUserRating(String itemId, {required bool likes}) async {
    final userId = _getUserId();
    await _dio.post(
      '/Users/$userId/Items/$itemId/Rating',
      queryParameters: {'Likes': likes},
    );
  }

  @override
  Future<void> deleteUserRating(String itemId) async {
    final userId = _getUserId();
    await _dio.delete('/Users/$userId/Items/$itemId/Rating');
  }

  @override
  Future<Map<String, dynamic>> getItem(String itemId) async {
    final userId = _getUserId();
    final response = await _dio.get('/Users/$userId/Items/$itemId');
    return response.data as Map<String, dynamic>;
  }
}
