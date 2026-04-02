abstract class ImageApi {
  String getPrimaryImageUrl(
    String itemId, {
    int? maxWidth,
    int? maxHeight,
    String? tag,
  });

  String getBackdropImageUrl(
    String itemId, {
    int? maxWidth,
    int? index,
    String? tag,
  });

  String getLogoImageUrl(
    String itemId, {
    int? maxWidth,
    String? tag,
  });

  String getBannerImageUrl(
    String itemId, {
    int? maxWidth,
    String? tag,
  });

  String getThumbImageUrl(
    String itemId, {
    int? maxWidth,
    String? tag,
  });

  String getChapterImageUrl(
    String itemId, {
    required int index,
    int? maxWidth,
    String? tag,
  });

  String getUserImageUrl(String userId);

  String getTrickplayTileImageUrl(
    String itemId, {
    required int width,
    required int index,
    String? mediaSourceId,
  });
}
