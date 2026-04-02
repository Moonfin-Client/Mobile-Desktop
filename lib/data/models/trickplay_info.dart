class TrickplayInfo {
  final int width;
  final int height;
  final int tileWidth;
  final int tileHeight;
  final int interval;

  const TrickplayInfo({
    required this.width,
    required this.height,
    required this.tileWidth,
    required this.tileHeight,
    required this.interval,
  });

  bool get isValid =>
      width > 0 &&
      height > 0 &&
      tileWidth > 0 &&
      tileHeight > 0 &&
      interval > 0;

  int get tilesPerImage => tileWidth * tileHeight;

  static TrickplayInfo? fromItemData(
    Map<String, dynamic> rawData, {
    String? mediaSourceId,
  }) {
    final trickplay = rawData['Trickplay'] as Map<String, dynamic>?;
    if (trickplay == null || trickplay.isEmpty) return null;

    Map<String, dynamic>? resolutions;
    if (mediaSourceId != null && trickplay.containsKey(mediaSourceId)) {
      resolutions = (trickplay[mediaSourceId] as Map?)?.cast<String, dynamic>();
    }
    resolutions ??=
        (trickplay.values.first as Map?)?.cast<String, dynamic>();

    if (resolutions == null || resolutions.isEmpty) return null;

    final info =
        (resolutions.values.first as Map?)?.cast<String, dynamic>();
    if (info == null) return null;

    return TrickplayInfo(
      width: (info['Width'] as num?)?.toInt() ?? 0,
      height: (info['Height'] as num?)?.toInt() ?? 0,
      tileWidth: (info['TileWidth'] as num?)?.toInt() ?? 0,
      tileHeight: (info['TileHeight'] as num?)?.toInt() ?? 0,
      interval: (info['Interval'] as num?)?.toInt() ?? 0,
    );
  }
}
