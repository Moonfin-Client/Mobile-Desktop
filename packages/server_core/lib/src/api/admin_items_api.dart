import '../models/enums.dart';

abstract class AdminItemsApi {
  Future<void> updateItem(String itemId, Map<String, dynamic> itemData);
  Future<Map<String, dynamic>> getMetadataEditor(String itemId);
  Future<void> updateContentType(String itemId, String contentType);
  Future<void> refreshItem(
    String itemId, {
    bool? recursive,
    bool? replaceAllMetadata,
    bool? replaceAllImages,
  });
  Future<List<Map<String, dynamic>>> getExternalIdInfos(String itemId);
  Future<List<Map<String, dynamic>>> searchRemotePerson(
    Map<String, dynamic> query,
  );
  Future<void> applyRemoteSearchResult(
    String itemId,
    Map<String, dynamic> result,
  );
  Future<Map<String, dynamic>> getRemoteImages(
    String itemId, {
    required ImageType imageType,
    int? startIndex,
    int? limit,
    String? providerName,
    bool? includeAllLanguages,
  });
  Future<void> downloadRemoteImage(
    String itemId, {
    required ImageType imageType,
    required String imageUrl,
  });
  Future<void> uploadItemImage(
    String itemId, {
    required ImageType imageType,
    required List<int> bytes,
    required String contentType,
  });
  Future<void> deleteItemImage(
    String itemId, {
    required ImageType imageType,
    int? imageIndex,
  });
}
