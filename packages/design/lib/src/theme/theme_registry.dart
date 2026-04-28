import 'theme_spec.dart';
import 'themes/moonfin_theme_spec.dart';
import 'themes/neon_pulse_theme_spec.dart';

class ThemeRegistry {
  const ThemeRegistry._();

  static const String moonfinId = 'moonfin';
  static const String neonPulseId = 'neon_pulse';

  static const Map<String, ThemeSpec> availableThemes = {
    moonfinId: moonfinThemeSpec,
    neonPulseId: neonPulseThemeSpec,
  };

  static ThemeSpec _active = moonfinThemeSpec;

  static ThemeSpec get active => _active;

  static void setActiveById(String id) {
    _active = availableThemes[id] ?? moonfinThemeSpec;
  }

  static ThemeSpec resolveById(String id) {
    return availableThemes[id] ?? moonfinThemeSpec;
  }
}
