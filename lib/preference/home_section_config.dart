import 'dart:convert';
import 'preference_constants.dart';

/// Categorizes a [HomeSectionConfig].
///
/// `builtin` entries map to a [HomeSectionType] handled natively by the app.
/// `pluginDynamic` entries are dynamic rows discovered from the third-party
/// "Home Screen Sections" Jellyfin plugin and are scoped to a specific
/// server.
enum HomeSectionKind {
  builtin('builtin'),
  pluginDynamic('pluginDynamic');

  const HomeSectionKind(this.serializedName);
  final String serializedName;

  static HomeSectionKind fromSerialized(String? value) {
    for (final v in HomeSectionKind.values) {
      if (v.serializedName == value) return v;
    }
    return HomeSectionKind.builtin;
  }
}

class HomeSectionConfig {
  final HomeSectionKind kind;
  final HomeSectionType type;
  final bool enabled;
  final int order;

  // pluginDynamic-only fields. Always null for builtin entries.
  final String? serverId;
  final String? pluginSection;
  final String? pluginAdditionalData;
  final String? pluginDisplayText;

  const HomeSectionConfig({
    this.kind = HomeSectionKind.builtin,
    this.type = HomeSectionType.none,
    this.enabled = true,
    this.order = 0,
    this.serverId,
    this.pluginSection,
    this.pluginAdditionalData,
    this.pluginDisplayText,
  });

  factory HomeSectionConfig.pluginDynamic({
    required String serverId,
    required String pluginSection,
    String? pluginAdditionalData,
    String? pluginDisplayText,
    bool enabled = true,
    int order = 0,
  }) =>
      HomeSectionConfig(
        kind: HomeSectionKind.pluginDynamic,
        type: HomeSectionType.none,
        enabled: enabled,
        order: order,
        serverId: serverId,
        pluginSection: pluginSection,
        pluginAdditionalData: pluginAdditionalData,
        pluginDisplayText: pluginDisplayText,
      );

  factory HomeSectionConfig.fromJson(Map<String, dynamic> json) {
    final kindRaw = json['kind'] as String?;
    final kind = kindRaw == null
        ? HomeSectionKind.builtin
        : HomeSectionKind.fromSerialized(kindRaw);
    final typeName = json['type'] as String? ?? 'none';
    return HomeSectionConfig(
      kind: kind,
      type: HomeSectionType.fromSerialized(typeName),
      enabled: json['enabled'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
      serverId: json['serverId'] as String?,
      pluginSection: json['pluginSection'] as String?,
      pluginAdditionalData: json['pluginAdditionalData'] as String?,
      pluginDisplayText: json['pluginDisplayText'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type.serializedName,
      'enabled': enabled,
      'order': order,
    };
    if (kind != HomeSectionKind.builtin) {
      json['kind'] = kind.serializedName;
      if (serverId != null) json['serverId'] = serverId;
      if (pluginSection != null) json['pluginSection'] = pluginSection;
      if (pluginAdditionalData != null) {
        json['pluginAdditionalData'] = pluginAdditionalData;
      }
      if (pluginDisplayText != null) {
        json['pluginDisplayText'] = pluginDisplayText;
      }
    }
    return json;
  }

  HomeSectionConfig copyWith({
    HomeSectionKind? kind,
    HomeSectionType? type,
    bool? enabled,
    int? order,
    String? serverId,
    String? pluginSection,
    String? pluginAdditionalData,
    String? pluginDisplayText,
  }) =>
      HomeSectionConfig(
        kind: kind ?? this.kind,
        type: type ?? this.type,
        enabled: enabled ?? this.enabled,
        order: order ?? this.order,
        serverId: serverId ?? this.serverId,
        pluginSection: pluginSection ?? this.pluginSection,
        pluginAdditionalData:
            pluginAdditionalData ?? this.pluginAdditionalData,
        pluginDisplayText: pluginDisplayText ?? this.pluginDisplayText,
      );

  /// Stable identifier suitable for use as a row id / list key. Plugin
  /// entries combine the originating server, section and additional data so
  /// multiple instances of the same section can coexist.
  String get stableId {
    if (kind == HomeSectionKind.pluginDynamic) {
      return 'pluginDynamic:${serverId ?? ''}:${pluginSection ?? ''}:${pluginAdditionalData ?? ''}';
    }
    return 'builtin:${type.serializedName}';
  }

  bool get isBuiltin => kind == HomeSectionKind.builtin;
  bool get isPluginDynamic => kind == HomeSectionKind.pluginDynamic;

  static List<HomeSectionConfig> defaults() => const [
        HomeSectionConfig(type: HomeSectionType.libraryTilesSmall, enabled: true, order: 0),
        HomeSectionConfig(type: HomeSectionType.resume, enabled: true, order: 1),
        HomeSectionConfig(type: HomeSectionType.nextUp, enabled: true, order: 2),
        HomeSectionConfig(type: HomeSectionType.latestMedia, enabled: true, order: 3),
        HomeSectionConfig(type: HomeSectionType.recentlyReleased, enabled: false, order: 4),
        HomeSectionConfig(type: HomeSectionType.liveTv, enabled: false, order: 5),
        HomeSectionConfig(type: HomeSectionType.libraryButtons, enabled: false, order: 6),
        HomeSectionConfig(type: HomeSectionType.resumeAudio, enabled: false, order: 7),
        HomeSectionConfig(type: HomeSectionType.resumeBook, enabled: false, order: 8),
        HomeSectionConfig(type: HomeSectionType.activeRecordings, enabled: false, order: 9),
        HomeSectionConfig(type: HomeSectionType.playlists, enabled: false, order: 10),
      ];

  static List<HomeSectionConfig> fromJsonString(String jsonString) {
    if (jsonString.isEmpty) return defaults();
    try {
      final list = jsonDecode(jsonString) as List;
      return list
          .map((e) => HomeSectionConfig.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return defaults();
    }
  }

  static String toJsonString(List<HomeSectionConfig> configs) =>
      jsonEncode(configs.map((c) => c.toJson()).toList());
}
