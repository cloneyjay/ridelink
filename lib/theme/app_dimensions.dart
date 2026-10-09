/// Spacing, radius, and minimum tap-target constants from the RideLink
/// design system (tokens.json).  All values are on the 4 px grid.
/// These are not theme-dependent — use directly without BuildContext.
abstract final class AppSpacing {
  static const double s1  = 4;   // micro gap: icon-to-label
  static const double s2  = 8;   // small: tag padding, tight list gap
  static const double s3  = 12;  // compact row gap, inner card gap
  static const double s4  = 16;  // standard card padding — base grid unit
  static const double s5  = 20;  // slightly loose rows
  static const double s6  = 24;  // card-to-card gap, section headers
  static const double s8  = 32;  // major section breaks
  static const double s10 = 40;  // hero vertical spacing
  static const double s12 = 48;  // bottom-nav safe-area buffer
  static const double s16 = 64;  // full-screen gutter on larger phones
}

abstract final class AppRadius {
  static const double sm   = 6;     // chips, badges, status tags
  static const double md   = 10;    // buttons, inputs, map panels
  static const double lg   = 16;    // cards, rider profile tiles
  static const double xl   = 24;    // bottom-sheet top corners only
  static const double full = 9999;  // pills, FABs, avatars, online dots
}

abstract final class AppLayout {
  /// Every interactive element must meet this minimum.
  static const double minTapTarget = 44;

  /// Bottom nav height including home-indicator buffer.
  static const double bottomNavHeight = 84;

  /// Home-indicator safe-area clearance (space-12).
  static const double homeIndicatorBuffer = AppSpacing.s12;

  /// Standard screen-edge horizontal padding.
  static const double screenPadding = AppSpacing.s4;

  /// Bottom-sheet top corner radius.
  static const double sheetTopRadius = AppRadius.xl;
}
