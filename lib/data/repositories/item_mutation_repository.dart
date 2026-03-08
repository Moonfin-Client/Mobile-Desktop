import 'package:server_core/server_core.dart';

class ItemMutationRepository {
  final MediaServerClient _client;

  ItemMutationRepository(this._client);

  Future<void> setFavorite(String itemId, {required bool isFavorite}) async {
    if (isFavorite) {
      await _client.userLibraryApi.markFavorite(itemId);
    } else {
      await _client.userLibraryApi.unmarkFavorite(itemId);
    }
  }

  Future<void> setPlayed(String itemId, {required bool isPlayed}) async {
    if (isPlayed) {
      await _client.userLibraryApi.markPlayed(itemId);
    } else {
      await _client.userLibraryApi.unmarkPlayed(itemId);
    }
  }

  Future<void> setRating(String itemId, {required bool likes}) async {
    await _client.userLibraryApi.updateUserRating(itemId, likes: likes);
  }

  Future<void> clearRating(String itemId) async {
    await _client.userLibraryApi.deleteUserRating(itemId);
  }
}
