import 'package:flutter/material.dart';

class AppColors {
  const AppColors();

  // Semantic colors (backward compat)
  Color get primary => cyan500;
  Color get primaryVariant => const Color(0xFF0086B3);
  Color get secondary => const Color(0xFFAA5CC3);
  Color get background => black700;
  Color get surface => black500;
  Color get surfaceVariant => const Color(0xFF252525);
  Color get card => const Color(0xFF202020);
  Color get onPrimary => Colors.white;
  Color get onBackground => Colors.white;
  Color get onSurface => Colors.white;
  Color get onSurfaceVariant => white500;
  Color get textSecondary => const Color(0xFF999999);
  Color get error => const Color(0xFFCF6679);
  Color get success => green500;
  Color get warning => const Color(0xFFFFC107);

  // Black
  static const Color black = Color(0xFF000000);
  static const Color black400 = Color(0xFF282828);
  static const Color black500 = Color(0xFF1A1A1A);
  static const Color black600 = Color(0xFF141414);
  static const Color black700 = Color(0xFF101010);
  static const Color black800 = Color(0xFF0C0C0C);
  static const Color black900 = Color(0xFF080808);

  // White
  static const Color white = Color(0xFFFFFFFF);
  static const Color white100 = Color(0xFFFAFAFA);
  static const Color white200 = Color(0xFFF5F5F5);
  static const Color white300 = Color(0xFFE0E0E0);
  static const Color white400 = Color(0xFFCCCCCC);
  static const Color white500 = Color(0xFFB3B3B3);

  // Blue
  static const Color blue100 = Color(0xFFBBDEFB);
  static const Color blue200 = Color(0xFF90CAF9);
  static const Color blue300 = Color(0xFF64B5F6);
  static const Color blue400 = Color(0xFF42A5F5);
  static const Color blue500 = Color(0xFF2196F3);
  static const Color blue600 = Color(0xFF1E88E5);
  static const Color blue700 = Color(0xFF1976D2);
  static const Color blue800 = Color(0xFF1565C0);
  static const Color blue900 = Color(0xFF0D47A1);

  // Blue Grey
  static const Color bluegrey100 = Color(0xFFCFD8DC);
  static const Color bluegrey200 = Color(0xFFB0BEC5);
  static const Color bluegrey300 = Color(0xFF90A4AE);
  static const Color bluegrey400 = Color(0xFF78909C);
  static const Color bluegrey500 = Color(0xFF607D8B);
  static const Color bluegrey600 = Color(0xFF546E7A);
  static const Color bluegrey700 = Color(0xFF455A64);
  static const Color bluegrey800 = Color(0xFF37474F);
  static const Color bluegrey900 = Color(0xFF263238);

  // Cyan
  static const Color cyan100 = Color(0xFFB2EBF2);
  static const Color cyan200 = Color(0xFF80DEEA);
  static const Color cyan300 = Color(0xFF4DD0E1);
  static const Color cyan400 = Color(0xFF26C6DA);
  static const Color cyan500 = Color(0xFF00A4DC); // Jellyfin blue / accent
  static const Color cyan600 = Color(0xFF00ACC1);
  static const Color cyan700 = Color(0xFF0097A7);
  static const Color cyan800 = Color(0xFF00838F);
  static const Color cyan900 = Color(0xFF006064);

  // Green
  static const Color green100 = Color(0xFFC8E6C9);
  static const Color green200 = Color(0xFFA5D6A7);
  static const Color green300 = Color(0xFF81C784);
  static const Color green400 = Color(0xFF66BB6A);
  static const Color green500 = Color(0xFF4CAF50);
  static const Color green600 = Color(0xFF43A047);
  static const Color green700 = Color(0xFF388E3C);
  static const Color green800 = Color(0xFF2E7D32);
  static const Color green900 = Color(0xFF1B5E20);

  // Grey
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Lime
  static const Color lime100 = Color(0xFFF0F4C3);
  static const Color lime200 = Color(0xFFE6EE9C);
  static const Color lime300 = Color(0xFFDCE775);
  static const Color lime400 = Color(0xFFD4E157);
  static const Color lime500 = Color(0xFFCDDC39);
  static const Color lime600 = Color(0xFFC0CA33);
  static const Color lime700 = Color(0xFFAFB42B);
  static const Color lime800 = Color(0xFF9E9D24);
  static const Color lime900 = Color(0xFF827717);

  // Magenta
  static const Color magenta100 = Color(0xFFF8BBD0);
  static const Color magenta200 = Color(0xFFF48FB1);
  static const Color magenta300 = Color(0xFFF06292);
  static const Color magenta400 = Color(0xFFEC407A);
  static const Color magenta500 = Color(0xFFE91E63);
  static const Color magenta600 = Color(0xFFD81B60);
  static const Color magenta700 = Color(0xFFC2185B);
  static const Color magenta800 = Color(0xFFAD1457);
  static const Color magenta900 = Color(0xFF880E4F);

  // Orange
  static const Color orange100 = Color(0xFFFFE0B2);
  static const Color orange200 = Color(0xFFFFCC80);
  static const Color orange300 = Color(0xFFFFB74D);
  static const Color orange400 = Color(0xFFFFA726);
  static const Color orange500 = Color(0xFFFF9800);
  static const Color orange600 = Color(0xFFFB8C00);
  static const Color orange700 = Color(0xFFF57C00);
  static const Color orange800 = Color(0xFFEF6C00);
  static const Color orange900 = Color(0xFFE65100);

  // Purple
  static const Color purple100 = Color(0xFFE1BEE7);
  static const Color purple200 = Color(0xFFCE93D8);
  static const Color purple300 = Color(0xFFBA68C8);
  static const Color purple400 = Color(0xFFAB47BC);
  static const Color purple500 = Color(0xFF9C27B0);
  static const Color purple600 = Color(0xFF8E24AA);
  static const Color purple700 = Color(0xFF7B1FA2);
  static const Color purple800 = Color(0xFF6A1B9A);
  static const Color purple900 = Color(0xFF4A148C);

  // Red
  static const Color red100 = Color(0xFFFFCDD2);
  static const Color red200 = Color(0xFFEF9A9A);
  static const Color red300 = Color(0xFFE57373);
  static const Color red400 = Color(0xFFEF5350);
  static const Color red500 = Color(0xFFF44336);
  static const Color red600 = Color(0xFFE53935);
  static const Color red700 = Color(0xFFD32F2F);
  static const Color red800 = Color(0xFFC62828);
  static const Color red900 = Color(0xFFB71C1C);

  // Yellow
  static const Color yellow100 = Color(0xFFFFF9C4);
  static const Color yellow200 = Color(0xFFFFF59D);
  static const Color yellow300 = Color(0xFFFFF176);
  static const Color yellow400 = Color(0xFFFFEE58);
  static const Color yellow500 = Color(0xFFFFEB3B);
  static const Color yellow600 = Color(0xFFFDD835);
  static const Color yellow700 = Color(0xFFFBC02D);
  static const Color yellow800 = Color(0xFFF9A825);
  static const Color yellow900 = Color(0xFFF57F17);
}
