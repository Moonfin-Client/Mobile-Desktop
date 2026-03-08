import '../models/system_models.dart';

abstract class DisplayPreferencesApi {
  Future<DisplayPreferences> getDisplayPreferences(
    String id, {
    String? client,
  });

  Future<void> saveDisplayPreferences(
    String id,
    DisplayPreferences prefs, {
    String? client,
  });
}
