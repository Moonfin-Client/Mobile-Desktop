import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography();

  static const double fontSize2xs = 10;
  static const double fontSizeXs = 12;
  static const double fontSizeSm = 14;
  static const double fontSizeMd = 16;
  static const double fontSizeLg = 18;
  static const double fontSizeXl = 20;
  static const double fontSize2xl = 24;
  static const double fontSize3xl = 32;

  TextStyle get displayLarge => const TextStyle(
        fontSize: fontSize3xl,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  TextStyle get displayMedium => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      );

  TextStyle get headlineLarge => const TextStyle(
        fontSize: fontSize2xl,
        fontWeight: FontWeight.w600,
      );

  TextStyle get headlineMedium => const TextStyle(
        fontSize: fontSizeXl,
        fontWeight: FontWeight.w600,
      );

  TextStyle get titleLarge => const TextStyle(
        fontSize: fontSizeLg,
        fontWeight: FontWeight.w500,
      );

  TextStyle get titleMedium => const TextStyle(
        fontSize: fontSizeMd,
        fontWeight: FontWeight.w500,
      );

  TextStyle get bodyLarge => const TextStyle(
        fontSize: fontSizeMd,
        fontWeight: FontWeight.normal,
      );

  TextStyle get bodyMedium => const TextStyle(
        fontSize: fontSizeSm,
        fontWeight: FontWeight.normal,
      );

  TextStyle get bodySmall => const TextStyle(
        fontSize: fontSizeXs,
        fontWeight: FontWeight.normal,
      );

  TextStyle get labelLarge => const TextStyle(
        fontSize: fontSizeSm,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  TextStyle get labelMedium => const TextStyle(
        fontSize: fontSizeXs,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );

  TextStyle get labelSmall => const TextStyle(
        fontSize: fontSize2xs,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );
}
