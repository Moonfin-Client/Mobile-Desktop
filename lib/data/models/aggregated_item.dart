class AggregatedItem {
  final String id;
  final String serverId;
  final Map<String, dynamic> rawData;

  const AggregatedItem({
    required this.id,
    required this.serverId,
    required this.rawData,
  });

  String get name => rawData['Name'] as String? ?? '';
  String? get type => rawData['Type'] as String?;
  String? get seriesName => rawData['SeriesName'] as String?;
  int? get productionYear => rawData['ProductionYear'] as int?;
  double? get communityRating => rawData['CommunityRating'] as double?;
}
