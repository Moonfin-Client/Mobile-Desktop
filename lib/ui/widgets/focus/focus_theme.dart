import 'package:flutter/material.dart';
import 'package:jellyfin_design/jellyfin_design.dart';

class FocusTheme {
  static const double scale = 1.02;
  static const double defaultBorderRadius = 8.0;
  static const Duration animationDuration = Duration(milliseconds: 150);

  static double get borderWidth => ThemeRegistry.active.borders.focusBorder.width;

  static BoxDecoration focusDecoration({
    required bool isFocused,
    double radius = defaultBorderRadius,
    Color? color,
    Color? backgroundColor,
  }) {
    final borders = ThemeRegistry.active.borders;
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(radius),
      border: isFocused && color != null
          ? Border.fromBorderSide(
              borders.focusBorder.copyWith(color: color),
            )
          : null,
      boxShadow: isFocused && borders.focusGlow.isNotEmpty
          ? borders.focusGlow
          : null,
    );
  }

  static Color resolveColor(BuildContext context, Color? override) =>
      override ?? Theme.of(context).colorScheme.primary;
}
