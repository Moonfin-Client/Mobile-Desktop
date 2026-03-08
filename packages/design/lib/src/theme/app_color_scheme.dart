import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppColorScheme {
  const AppColorScheme._();

  // Background & Surface
  static const Color background = AppColors.black700;
  static const Color onBackground = AppColors.white;
  static const Color surface = AppColors.black500;
  static const Color onSurface = AppColors.white;
  static const Color surfaceVariant = Color(0xFF252525);
  static const Color scrim = Color(0xCC000000);

  // Accent
  static const Color accent = AppColors.cyan500;
  static const Color onAccent = AppColors.white;

  // Buttons
  static const Color buttonNormal = Color(0xFF2A2A2A);
  static const Color buttonFocused = AppColors.cyan500;
  static const Color buttonDisabled = Color(0xFF1E1E1E);
  static const Color buttonActive = Color(0xFF3A3A3A);
  static const Color onButtonNormal = AppColors.white;
  static const Color onButtonFocused = AppColors.white;
  static const Color onButtonDisabled = Color(0xFF666666);

  // Input
  static const Color inputBackground = Color(0xFF2A2A2A);
  static const Color inputFocused = Color(0xFF3A3A3A);
  static const Color inputBorder = Color(0xFF404040);
  static const Color inputBorderFocused = AppColors.cyan500;

  // Range / Seekbar
  static const Color rangeTrack = Color(0xFF404040);
  static const Color rangeProgress = AppColors.cyan500;
  static const Color rangeThumb = AppColors.cyan500;
  static const Color seekbarBuffered = Color(0x80FFFFFF);

  // Badge
  static const Color badgeBackground = AppColors.cyan500;
  static const Color onBadge = AppColors.white;
  static const Color badgeUnplayed = AppColors.cyan500;
  static const Color badgeWatched = AppColors.green500;

  // Recording
  static const Color recordingActive = AppColors.red500;
  static const Color recordingScheduled = AppColors.orange500;

  // Focus border presets
  static const Map<String, Color> focusBorderPresets = {
    'White': AppColors.white,
    'Black': AppColors.black,
    'Gray': AppColors.grey500,
    'Dark Blue': AppColors.blue900,
    'Purple': AppColors.purple700,
    'Teal': Color(0xFF00897B),
    'Navy': Color(0xFF1A237E),
    'Charcoal': AppColors.bluegrey800,
    'Brown': Color(0xFF5D4037),
    'Dark Red': AppColors.red900,
    'Dark Green': AppColors.green900,
    'Slate': AppColors.bluegrey600,
    'Indigo': Color(0xFF283593),
  };

  static const Color defaultFocusBorder = AppColors.white;
}
