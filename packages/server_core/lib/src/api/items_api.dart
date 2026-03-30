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
    List<String>? genres,
    bool? isFavorite,
    bool? collapseBoxSetItems,
    bool? enableTotalRecordCount,
  });

  Future<Map<String, dynamic>> getItem(String itemId);
  Future<Map<String, dynamic>> getSimilarItems(String itemId, {int? limit});

  Future<Map<String, dynamic>> getNextUp({
    String? seriesId,
    String? parentId,
    int? limit,
    String? fields,
    bool? enableResumable,
  });

  Future<Map<String, dynamic>> getResumeItems({
    String? parentId,
    List<String>? includeItemTypes,
    int? limit,
    String? fields,
  });

  Future<Map<String, dynamic>> getLatestItems({
    String? parentId,
    List<String>? includeItemTypes,
    int? limit,
    String? fields,
  });

  Future<Map<String, dynamic>> getSeasons(String seriesId);

  Future<Map<String, dynamic>> getEpisodes(
    String seriesId, {
    String? seasonId,
    String? fields,
  });

  Future<Map<String, dynamic>> getThemeMedia(String itemId, {bool inheritFromParent = true});

  Future<Map<String, dynamic>> getPlaylists();

  Future<Map<String, dynamic>> getArtists({
    String? parentId,
    String? userId,
    String? sortBy,
    String? sortOrder,
    int? startIndex,
    int? limit,
    bool? recursive,
    String? fields,
    String? nameStartsWith,
    bool? isFavorite,
  });

  Future<Map<String, dynamic>> getAlbumArtists({
    String? parentId,
    String? userId,
    String? sortBy,
    String? sortOrder,
    int? startIndex,
    int? limit,
    bool? recursive,
    String? fields,
    String? nameStartsWith,
    bool? isFavorite,
  });

  Future<Map<String, dynamic>> getPlaylistItems(String playlistId);

  Future<Map<String, dynamic>> createPlaylist({
    required String name,
    List<String>? itemIds,
  });

  Future<void> addToPlaylist(String playlistId, List<String> itemIds);

  Future<void> removeFromPlaylist(String playlistId, List<String> entryIds);

  Future<void> movePlaylistItem(
    String playlistId,
    String playlistItemId,
    int newIndex,
  );

  Future<void> renamePlaylist(String playlistId, String name);

  Future<void> deletePlaylist(String playlistId);

  Future<Map<String, dynamic>> getGenres({
    String? parentId,
    String? userId,
    String? sortBy,
    String? sortOrder,
    int? startIndex,
    int? limit,
    bool? recursive,
    String? fields,
  });

  Future<Map<String, dynamic>> getLyrics(String itemId);

  Future<List<Map<String, dynamic>>> getSpecialFeatures(String itemId);

  Future<List<Map<String, dynamic>>> getMediaSegments(String itemId);

  Future<List<Map<String, dynamic>>> searchRemoteSubtitles(
    String itemId, {
    required String language,
    bool? isPerfectMatch,
  });

  Future<void> downloadRemoteSubtitle(String itemId, String subtitleId);
}
