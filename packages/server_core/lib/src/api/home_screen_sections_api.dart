import '../models/home_screen_section_models.dart';

/// Client surface for the third-party "Home Screen Sections" Jellyfin plugin.
///
/// Methods may throw on transport / HTTP failures; callers should treat any
/// failure as "plugin unavailable" and fall back to the built-in home rows.
abstract class HomeScreenSectionsApi {
  /// GET /HomeScreen/Meta
  Future<HomeScreenMeta> getMeta();

  /// GET /HomeScreen/Sections
  Future<List<HomeScreenSectionInfo>> getUserSections();

  /// GET /HomeScreen/Section/{sectionType}
  Future<Map<String, dynamic>> getSectionItems(
    String sectionType, {
    String? additionalData,
  });
}
