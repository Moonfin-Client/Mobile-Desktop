import 'package:flutter/material.dart';

@immutable
class ThemeColorTokens {
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color scrim;
  final Color accent;
  final Color onAccent;
  final Color buttonNormal;
  final Color buttonFocused;
  final Color buttonDisabled;
  final Color buttonActive;
  final Color onButtonNormal;
  final Color onButtonFocused;
  final Color onButtonDisabled;
  final Color inputBackground;
  final Color inputFocused;
  final Color inputBorder;
  final Color inputBorderFocused;
  final Color rangeTrack;
  final Color rangeProgress;
  final Color rangeThumb;
  final Color seekbarBuffered;
  final Color badgeBackground;
  final Color onBadge;
  final Color badgeUnplayed;
  final Color badgeWatched;
  final Color recordingActive;
  final Color recordingScheduled;

  const ThemeColorTokens({
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.scrim,
    required this.accent,
    required this.onAccent,
    required this.buttonNormal,
    required this.buttonFocused,
    required this.buttonDisabled,
    required this.buttonActive,
    required this.onButtonNormal,
    required this.onButtonFocused,
    required this.onButtonDisabled,
    required this.inputBackground,
    required this.inputFocused,
    required this.inputBorder,
    required this.inputBorderFocused,
    required this.rangeTrack,
    required this.rangeProgress,
    required this.rangeThumb,
    required this.seekbarBuffered,
    required this.badgeBackground,
    required this.onBadge,
    required this.badgeUnplayed,
    required this.badgeWatched,
    required this.recordingActive,
    required this.recordingScheduled,
  });
}

@immutable
class ThemeBorderTokens {
  final BorderSide cardBorder;
  final BorderSide chipBorder;
  final BorderSide focusBorder;
  final BorderRadius cardRadius;
  final BorderRadius chipRadius;
  final Color chipBackground;
  final List<BoxShadow> focusGlow;

  const ThemeBorderTokens({
    required this.cardBorder,
    required this.chipBorder,
    required this.focusBorder,
    required this.cardRadius,
    required this.chipRadius,
    required this.chipBackground,
    required this.focusGlow,
  });
}

@immutable
class ThemeSpec {
  final String id;
  final String displayName;
  final Brightness brightness;
  final ThemeColorTokens colors;
  final ThemeBorderTokens borders;

  const ThemeSpec({
    required this.id,
    required this.displayName,
    required this.brightness,
    required this.colors,
    required this.borders,
  });
}
