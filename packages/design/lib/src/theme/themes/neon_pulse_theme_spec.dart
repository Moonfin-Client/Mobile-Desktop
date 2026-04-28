import 'package:flutter/material.dart';

import '../theme_spec.dart';

const neonPulseThemeSpec = ThemeSpec(
  id: 'neon_pulse',
  displayName: 'Neon Pulse',
  brightness: Brightness.dark,
  colors: ThemeColorTokens(
    background: Color(0xFF0B0420),
    onBackground: Color(0xFF00E5FF),
    surface: Color(0xCC1E0A3F),
    onSurface: Color(0xFF00E5FF),
    surfaceVariant: Color(0xCC1E0A3F),
    scrim: Color(0xCC0B0420),
    accent: Color(0xFFFF2E92),
    onAccent: Color(0xFFFFFFFF),
    buttonNormal: Color(0x00000000),
    buttonFocused: Color(0x33FF2E92),
    buttonDisabled: Color(0x22FFFFFF),
    buttonActive: Color(0x33FF2E92),
    onButtonNormal: Color(0xFFFF2E92),
    onButtonFocused: Color(0xFFFFFFFF),
    onButtonDisabled: Color(0xAAFFFFFF),
    inputBackground: Color(0x331E0A3F),
    inputFocused: Color(0x441E0A3F),
    inputBorder: Color(0x66FF2E92),
    inputBorderFocused: Color(0xFFFF2E92),
    rangeTrack: Color(0x66201840),
    rangeProgress: Color(0xFFFF2E92),
    rangeThumb: Color(0xFFFF2E92),
    seekbarBuffered: Color(0x66FFFFFF),
    badgeBackground: Color(0xFFFF2E92),
    onBadge: Color(0xFFFFFFFF),
    badgeUnplayed: Color(0xFFFF2E92),
    badgeWatched: Color(0xFF00E5FF),
    recordingActive: Color(0xFFFF2E92),
    recordingScheduled: Color(0xFF00E5FF),
  ),
  borders: ThemeBorderTokens(
    cardBorder: BorderSide(color: Color(0x66FF2E92)),
    chipBorder: BorderSide(color: Color(0xCCFF2E92), width: 1.2),
    focusBorder: BorderSide(color: Color(0xFFFF2E92), width: 1.4),
    cardRadius: BorderRadius.all(Radius.circular(10)),
    chipRadius: BorderRadius.all(Radius.circular(8)),
    chipBackground: Color(0x00000000),
    focusGlow: [
      BoxShadow(
        color: Color(0x99FF2E92),
        blurRadius: 8,
        spreadRadius: 0.5,
      ),
      BoxShadow(
        color: Color(0x6600E5FF),
        blurRadius: 5,
      ),
    ],
  ),
);
