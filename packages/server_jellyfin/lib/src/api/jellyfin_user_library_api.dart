import 'package:dio/dio.dart';
import 'package:server_core/server_core.dart';
import 'jellyfin_item_fields.dart';

class JellyfinUserLibraryApi implements UserLibraryApi {
  final Dio _dio;

  JellyfinUserLibraryApi(this._dio);

  @override
  Future<void> markFavorite(String itemId) async {
    await _dio.post('/UserFavoriteItems/$itemId');
  }

  @override
  Future<void> unmarkFavorite(String itemId) async {
    await _dio.delete('/UserFavoriteItems/$itemId');
  }

  @override
  Future<void> markPlayed(String itemId) async {
    await _dio.post('/UserPlayedItems/$itemId');
  }

  @override
  Future<void> unmarkPlayed(String itemId) async {
    await _dio.delete('/UserPlayedItems/$itemId');
  }

  @override
  Future<void> updateUserRating(String itemId, {required bool likes}) async {
    await _dio.post('/UserItems/$itemId/Rating', queryParameters: {
      'Likes': likes,
    });
  }

  @override
  Future<void> deleteUserRating(String itemId) async {
    await _dio.delete('/UserItems/$itemId/Rating');
  }

  @override
  Future<Map<String, dynamic>> getItem(String itemId) async {
    final response = await _dio.get('/Items/$itemId', queryParameters: {
      'Fields': kItemFields,
    });
    return response.data as Map<String, dynamic>;
  }
}
