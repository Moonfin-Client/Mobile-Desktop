import 'package:server_core/server_core.dart';

class JellyfinImageApi implements ImageApi {
  final String _baseUrl;

  JellyfinImageApi(this._baseUrl);

  String _buildQuery(Map<String, String> params) {
    if (params.isEmpty) return '';
    return '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
  }

  @override
  String getPrimaryImageUrl(
    String itemId, {
    int? maxWidth,
    int? maxHeight,
    String? tag,
  }) {
    final query = _buildQuery({
      if (maxWidth != null) 'maxWidth': maxWidth.toString(),
      if (maxHeight != null) 'maxHeight': maxHeight.toString(),
      if (tag != null) 'tag': tag,
    });
    return '$_baseUrl/Items/$itemId/Images/Primary$query';
  }

  @override
  String getBackdropImageUrl(
    String itemId, {
    int? maxWidth,
    int? index,
    String? tag,
  }) {
    final idx = index ?? 0;
    final query = _buildQuery({
      if (maxWidth != null) 'maxWidth': maxWidth.toString(),
      if (tag != null) 'tag': tag,
    });
    return '$_baseUrl/Items/$itemId/Images/Backdrop/$idx$query';
  }

  @override
  String getLogoImageUrl(
    String itemId, {
    int? maxWidth,
    String? tag,
  }) {
    final query = _buildQuery({
      if (maxWidth != null) 'maxWidth': maxWidth.toString(),
      if (tag != null) 'tag': tag,
    });
    return '$_baseUrl/Items/$itemId/Images/Logo$query';
  }

  @override
  String getBannerImageUrl(
    String itemId, {
    int? maxWidth,
    String? tag,
  }) {
    final query = _buildQuery({
      if (maxWidth != null) 'maxWidth': maxWidth.toString(),
      if (tag != null) 'tag': tag,
    });
    return '$_baseUrl/Items/$itemId/Images/Banner$query';
  }

  @override
  String getThumbImageUrl(
    String itemId, {
    int? maxWidth,
    String? tag,
  }) {
    final query = _buildQuery({
      if (maxWidth != null) 'maxWidth': maxWidth.toString(),
      if (tag != null) 'tag': tag,
    });
    return '$_baseUrl/Items/$itemId/Images/Thumb$query';
  }

  @override
  String getChapterImageUrl(
    String itemId, {
    required int index,
    int? maxWidth,
    String? tag,
  }) {
    final query = _buildQuery({
      if (maxWidth != null) 'maxWidth': maxWidth.toString(),
      if (tag != null) 'tag': tag,
    });
    return '$_baseUrl/Items/$itemId/Images/Chapter/$index$query';
  }

  @override
  String getUserImageUrl(String userId) {
    return '$_baseUrl/Users/$userId/Images/Primary';
  }

  @override
  String getTrickplayTileImageUrl(
    String itemId, {
    required int width,
    required int index,
    String? mediaSourceId,
  }) {
    final query = _buildQuery({
      if (mediaSourceId != null) 'mediaSourceId': mediaSourceId,
    });
    return '$_baseUrl/Videos/$itemId/Trickplay/$width/$index.jpg$query';
  }
}
