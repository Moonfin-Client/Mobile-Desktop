abstract class ItemsApi {
  Future<Map<String, dynamic>> getItems({
    String? parentId,
    List<String>? includeItemTypes,
    String? sortBy,
    String? sortOrder,
    int? startIndex,
    int? limit,
    bool? recursive,
    String? searchTerm,
    String? fields,
    List<String>? personIds,
    List<String>? artistIds,
  });

  Future<Map<String, dynamic>> getItem(String itemId);
  Future<Map<String, dynamic>> getSimilarItems(String itemId, {int? limit});

  Future<Map<String, dynamic>> getNextUp({
    String? seriesId,
    int? limit,
  });

  Future<Map<String, dynamic>> getResumeItems({
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
}
