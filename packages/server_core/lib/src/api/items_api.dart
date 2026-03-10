abstract class ItemsApi {
  Future<Map<String, dynamic>> getItems({
    String? parentId,
    List<String>? includeItemTypes,
    List<String>? excludeItemTypes,
    String? sortBy,
    String? sortOrder,
    int? startIndex,
    int? limit,
    bool? recursive,
    String? searchTerm,
    String? fields,
    List<String>? personIds,
    List<String>? artistIds,
    List<String>? filters,
    List<String>? seriesStatus,
    String? nameStartsWith,
    List<String>? genreIds,
    bool? isFavorite,
    bool? collapseBoxSetItems,
  });

  Future<Map<String, dynamic>> getItem(String itemId);
  Future<Map<String, dynamic>> getSimilarItems(String itemId, {int? limit});

  Future<Map<String, dynamic>> getNextUp({
    String? seriesId,
    String? parentId,
    int? limit,
  });

  Future<Map<String, dynamic>> getResumeItems({
    String? parentId,
    List<String>? includeItemTypes,
    int? limit,
  });

  Future<Map<String, dynamic>> getLatestItems({
    String? parentId,
    List<String>? includeItemTypes,
    int? limit,
  });

  Future<Map<String, dynamic>> getSeasons(String seriesId);

  Future<Map<String, dynamic>> getEpisodes(
    String seriesId, {
    String? seasonId,
  });

  Future<Map<String, dynamic>> getThemeMedia(String itemId, {bool inheritFromParent = true});

  Future<Map<String, dynamic>> getPlaylists();

  Future<Map<String, dynamic>> createPlaylist({
    required String name,
    List<String>? itemIds,
  });

  Future<void> addToPlaylist(String playlistId, List<String> itemIds);
}
