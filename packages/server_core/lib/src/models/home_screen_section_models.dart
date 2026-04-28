// Models for the third-party "Home Screen Sections" Jellyfin plugin
// (GUID b8298e01-2697-407a-b44d-aa8dc795e850).

const String homeScreenSectionsPluginGuid =
    'b8298e01-2697-407a-b44d-aa8dc795e850';

class HomeScreenSectionInfo {
  final String section;
  final String displayText;
  final String? additionalData;

  const HomeScreenSectionInfo({
    required this.section,
    required this.displayText,
    this.additionalData,
  });

  factory HomeScreenSectionInfo.fromJson(Map<String, dynamic> json) =>
      HomeScreenSectionInfo(
        section: (json['Section'] as String?) ?? '',
        displayText: (json['DisplayText'] as String?) ?? '',
        additionalData: json['AdditionalData'] as String?,
      );
}

class HomeScreenMeta {
  final bool enabled;

  const HomeScreenMeta({this.enabled = false});

  factory HomeScreenMeta.fromJson(Map<String, dynamic> json) =>
      HomeScreenMeta(enabled: json['Enabled'] as bool? ?? false);
}
