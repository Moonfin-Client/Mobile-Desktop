class AppSpacing {
  const AppSpacing();

  static const double space2xs = 2;
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;
  static const double space2xl = 32;
  static const double space3xl = 48;

  // Aliases for backward compat
  double get xs => spaceXs;
  double get sm => spaceSm;
  double get md => spaceLg;
  double get lg => spaceXl;
  double get xl => space2xl;
  double get xxl => space3xl;

  double get cardPadding => spaceMd;
  double get screenPadding => spaceLg;
  double get sectionSpacing => spaceXl;

  // Radius tokens (moved to AppShapes but kept here for backward compat)
  double get cardRadius => 8;
  double get buttonRadius => 8;
  double get dialogRadius => 16;
}
