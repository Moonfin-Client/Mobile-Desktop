import 'package:flutter/material.dart';
import 'package:jellyfin_design/jellyfin_design.dart';

class AppTheme {
  const AppTheme._();

  static TextTheme _buildTextTheme(ThemeSpec spec) {
    final c = spec.colors;
    final isNeon = spec.id == ThemeRegistry.neonPulseId;
    final base = ThemeData(
      brightness: spec.brightness,
      fontFamily: isNeon ? 'NeonPulseDisplay' : null,
    ).textTheme;
    if (!isNeon) {
      return base;
    }

    const neonShadows = [
      Shadow(color: Color(0x99FF2E92), blurRadius: 6),
    ];

    TextStyle? neonDisplay(TextStyle? style) {
      if (style == null) return null;
      return style.copyWith(
        fontFamily: 'NeonPulseDisplay',
        color: c.accent,
        shadows: neonShadows,
        letterSpacing: (style.letterSpacing ?? 0) + 0.4,
      );
    }

    TextStyle? neonBody(TextStyle? style) {
      if (style == null) return null;
      return style.copyWith(
        color: c.onSurface,
        letterSpacing: 0.6,
      );
    }

    return base.copyWith(
      displayLarge: neonDisplay(base.displayLarge),
      displayMedium: neonDisplay(base.displayMedium),
      displaySmall: neonDisplay(base.displaySmall),
      headlineLarge: neonDisplay(base.headlineLarge),
      headlineMedium: neonDisplay(base.headlineMedium),
      headlineSmall: neonDisplay(base.headlineSmall),
      titleLarge: neonDisplay(base.titleLarge),
      titleMedium: neonDisplay(base.titleMedium),
      titleSmall: neonDisplay(base.titleSmall),
      bodyLarge: neonBody(base.bodyLarge),
      bodyMedium: neonBody(base.bodyMedium),
      bodySmall: neonBody(base.bodySmall),
      labelLarge: neonBody(base.labelLarge)?.copyWith(color: c.accent),
      labelMedium: neonBody(base.labelMedium),
      labelSmall: neonBody(base.labelSmall),
    );
  }

  static ThemeData buildTheme(ThemeSpec spec) {
    final c = spec.colors;
    final isNeon = spec.id == ThemeRegistry.neonPulseId;
    return ThemeData(
      useMaterial3: true,
      brightness: spec.brightness,
      fontFamily: isNeon ? 'NeonPulseDisplay' : null,
      colorScheme: ColorScheme.dark(
        primary: c.accent,
        secondary: JellyfinTokens.colors.secondary,
        surface: c.surface,
        surfaceContainerHighest: c.surfaceVariant,
        error: JellyfinTokens.colors.error,
        onPrimary: c.onAccent,
        onSurface: c.onSurface,
        scrim: c.scrim,
      ),
      scaffoldBackgroundColor: c.background,
      cardTheme: CardThemeData(
        color: JellyfinTokens.colors.card,
        shape: JellyfinTokens.shapes.smallShape,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.accent,
        unselectedItemColor: JellyfinTokens.colors.textSecondary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.buttonNormal,
          foregroundColor: c.onButtonNormal,
          disabledBackgroundColor: c.buttonDisabled,
          disabledForegroundColor: c.onButtonDisabled,
          shape: JellyfinTokens.shapes.smallShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.onSurface,
          side: BorderSide(color: c.inputBorder),
          shape: JellyfinTokens.shapes.smallShape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.inputBackground,
        border: OutlineInputBorder(
          borderRadius: JellyfinTokens.shapes.smallRadius,
          borderSide: BorderSide(color: c.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: JellyfinTokens.shapes.smallRadius,
          borderSide: BorderSide(color: c.inputBorderFocused, width: 2),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.rangeProgress,
        inactiveTrackColor: c.rangeTrack,
        thumbColor: c.rangeThumb,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.rangeProgress,
        linearTrackColor: c.rangeTrack,
      ),
      textTheme: _buildTextTheme(spec),
      chipTheme: ChipThemeData(
        backgroundColor: c.buttonNormal,
        shape: JellyfinTokens.shapes.extraLargeShape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: JellyfinTokens.shapes.largeShape,
      ),
    );
  }

  static final darkTheme = buildTheme(ThemeRegistry.resolveById(ThemeRegistry.moonfinId));
}
