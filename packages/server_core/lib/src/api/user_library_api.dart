abstract class UserLibraryApi {
  Future<void> markFavorite(String itemId);
  Future<void> unmarkFavorite(String itemId);
  Future<void> markPlayed(String itemId);
  Future<void> unmarkPlayed(String itemId);
  Future<void> updateUserRating(String itemId, {required bool likes});
  Future<void> deleteUserRating(String itemId);
  Future<Map<String, dynamic>> getItem(String itemId);
}
