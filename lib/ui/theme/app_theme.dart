import 'package:flutter/material.dart';
import 'package:jellyfin_design/jellyfin_design.dart';

class AppTheme {
  const AppTheme._();

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColorScheme.accent,
      secondary: JellyfinTokens.colors.secondary,
      surface: AppColorScheme.surface,
      surfaceContainerHighest: AppColorScheme.surfaceVariant,
      error: JellyfinTokens.colors.error,
      onPrimary: AppColorScheme.onAccent,
      onSurface: AppColorScheme.onSurface,
      scrim: AppColorScheme.scrim,
    ),
    scaffoldBackgroundColor: AppColorScheme.background,
    cardTheme: CardThemeData(
      color: JellyfinTokens.colors.card,
      shape: JellyfinTokens.shapes.smallShape,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColorScheme.background,
      elevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColorScheme.surface,
      selectedItemColor: AppColorScheme.accent,
      unselectedItemColor: JellyfinTokens.colors.textSecondary,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColorScheme.buttonNormal,
        foregroundColor: AppColorScheme.onButtonNormal,
        disabledBackgroundColor: AppColorScheme.buttonDisabled,
        disabledForegroundColor: AppColorScheme.onButtonDisabled,
        shape: JellyfinTokens.shapes.smallShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColorScheme.onSurface,
        side: const BorderSide(color: AppColorScheme.inputBorder),
        shape: JellyfinTokens.shapes.smallShape,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColorScheme.inputBackground,
      border: OutlineInputBorder(
        borderRadius: JellyfinTokens.shapes.smallRadius,
        borderSide: const BorderSide(color: AppColorScheme.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: JellyfinTokens.shapes.smallRadius,
        borderSide: const BorderSide(color: AppColorScheme.inputBorderFocused, width: 2),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColorScheme.rangeProgress,
      inactiveTrackColor: AppColorScheme.rangeTrack,
      thumbColor: AppColorScheme.rangeThumb,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColorScheme.rangeProgress,
      linearTrackColor: AppColorScheme.rangeTrack,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColorScheme.buttonNormal,
      shape: JellyfinTokens.shapes.extraLargeShape,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColorScheme.surface,
      shape: JellyfinTokens.shapes.largeShape,
    ),
  );
}
