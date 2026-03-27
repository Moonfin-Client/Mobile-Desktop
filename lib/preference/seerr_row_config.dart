import 'dart:convert';

import 'preference_constants.dart';

class SeerrRowConfig {
  final SeerrRowType type;
  final bool enabled;
  final int order;

  const SeerrRowConfig({
    required this.type,
    this.enabled = true,
    this.order = 0,
  });

  factory SeerrRowConfig.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'trending';
    return SeerrRowConfig(
      type: SeerrRowType.fromSerialized(typeName),
      enabled: json['enabled'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.serializedName,
        'enabled': enabled,
        'order': order,
      };

  SeerrRowConfig copyWith({
    SeerrRowType? type,
    bool? enabled,
    int? order,
  }) =>
      SeerrRowConfig(
        type: type ?? this.type,
        enabled: enabled ?? this.enabled,
        order: order ?? this.order,
      );

  static List<SeerrRowConfig> defaults() => const [
        SeerrRowConfig(type: SeerrRowType.recentRequests, order: 0),
        SeerrRowConfig(type: SeerrRowType.recentlyAdded, order: 1),
        SeerrRowConfig(type: SeerrRowType.trending, order: 2),
        SeerrRowConfig(type: SeerrRowType.popularMovies, order: 3),
        SeerrRowConfig(type: SeerrRowType.movieGenres, order: 4),
        SeerrRowConfig(type: SeerrRowType.upcomingMovies, order: 5),
        SeerrRowConfig(type: SeerrRowType.studios, order: 6),
        SeerrRowConfig(type: SeerrRowType.popularSeries, order: 7),
        SeerrRowConfig(type: SeerrRowType.seriesGenres, order: 8),
        SeerrRowConfig(type: SeerrRowType.upcomingSeries, order: 9),
        SeerrRowConfig(type: SeerrRowType.networks, order: 10),
      ];

  static List<SeerrRowConfig> fromJsonString(String jsonString) {
    if (jsonString.isEmpty) return defaults();
    try {
      final list = jsonDecode(jsonString) as List;
      return list
          .map((e) => SeerrRowConfig.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return defaults();
    }
  }

  static String toJsonString(List<SeerrRowConfig> configs) =>
      jsonEncode(configs.map((c) => c.toJson()).toList());
}
