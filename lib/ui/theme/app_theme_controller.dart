import 'package:flutter/material.dart';
import 'package:jellyfin_design/jellyfin_design.dart';

import '../../preference/preference_constants.dart';
import '../../preference/user_preferences.dart';

class AppThemeController extends ChangeNotifier {
  ThemeSpec _activeSpec;
  VisualThemeId _activeThemeId;

  AppThemeController(this._activeSpec, this._activeThemeId) {
    ThemeRegistry.setActiveById(_activeSpec.id);
  }

  ThemeSpec get activeSpec => _activeSpec;
  VisualThemeId get activeThemeId => _activeThemeId;

  static AppTheme _defaultFocusColorForTheme(VisualThemeId themeId) {
    return switch (themeId) {
      VisualThemeId.moonfin => AppTheme.moonfinCyan,
      VisualThemeId.neonPulse => AppTheme.neonPulseMagenta,
    };
  }

  void setByThemeId(VisualThemeId themeId) {
    if (themeId == _activeThemeId) return;
    final themeKey = switch (themeId) {
      VisualThemeId.moonfin => ThemeRegistry.moonfinId,
      VisualThemeId.neonPulse => ThemeRegistry.neonPulseId,
    };
    final resolved = ThemeRegistry.resolveById(themeKey);
    _activeThemeId = themeId;
    _activeSpec = resolved;
    ThemeRegistry.setActiveById(_activeSpec.id);
    notifyListeners();
  }

  Future<void> applyThemeSelection(
    UserPreferences prefs,
    VisualThemeId themeId,
  ) async {
    await prefs.set(UserPreferences.visualTheme, themeId);
    await prefs.set(UserPreferences.focusColor, _defaultFocusColorForTheme(themeId));
    setByThemeId(themeId);
  }

  static AppThemeController fromPreferences(UserPreferences prefs) {
    final prefTheme = prefs.get(UserPreferences.visualTheme);
    final initial = switch (prefTheme) {
      VisualThemeId.moonfin => ThemeRegistry.resolveById(ThemeRegistry.moonfinId),
      VisualThemeId.neonPulse => ThemeRegistry.resolveById(ThemeRegistry.neonPulseId),
    };
    return AppThemeController(initial, prefTheme);
  }
}

class AppThemeScope extends InheritedNotifier<AppThemeController> {
  const AppThemeScope({
    super.key,
    required AppThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppThemeScope>();
    assert(scope != null, 'No AppThemeScope found in context');
    return scope!.notifier!;
  }
}
