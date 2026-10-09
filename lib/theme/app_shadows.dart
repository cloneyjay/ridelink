import 'package:flutter/material.dart';

/// Shadow tokens from the RideLink design system (tokens.json).
/// Access via BuildContext: `context.shadows.md`
class AppShadows extends ThemeExtension<AppShadows> {
  const AppShadows({
    required this.sm,
    required this.md,
    required this.lg,
    required this.brand,
  });

  /// Subtle card lift — floating chips and inline surfaces.
  final List<BoxShadow> sm;

  /// Rider cards above map, action panels, moderate floating elevation.
  final List<BoxShadow> md;

  /// Bottom sheets, modals, FABs — maximum elevation.
  final List<BoxShadow> lg;

  /// Primary CTA glow — use only on the single most important action per screen.
  final List<BoxShadow> brand;

  static const light = AppShadows(
    sm: [
      BoxShadow(color: Color(0x1A000000), blurRadius: 3, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1)),
    ],
    md: [
      BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
      BoxShadow(color: Color(0x08000000), blurRadius: 4,  offset: Offset(0, 2)),
    ],
    lg: [
      BoxShadow(color: Color(0x18000000), blurRadius: 32, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x0C000000), blurRadius: 8,  offset: Offset(0, 4)),
    ],
    brand: [
      BoxShadow(color: Color(0x33C05818), blurRadius: 16, offset: Offset(0, 4)),
    ],
  );

  static const dark = AppShadows(
    sm: [
      BoxShadow(color: Color(0x4D000000), blurRadius: 3, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x33000000), blurRadius: 2, offset: Offset(0, 1)),
    ],
    md: [
      BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4)),
      BoxShadow(color: Color(0x33000000), blurRadius: 4,  offset: Offset(0, 2)),
    ],
    lg: [
      BoxShadow(color: Color(0x99000000), blurRadius: 32, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x4D000000), blurRadius: 8,  offset: Offset(0, 4)),
    ],
    brand: [
      BoxShadow(color: Color(0x66F08030), blurRadius: 16, offset: Offset(0, 4)),
    ],
  );

  @override
  AppShadows copyWith({
    List<BoxShadow>? sm,
    List<BoxShadow>? md,
    List<BoxShadow>? lg,
    List<BoxShadow>? brand,
  }) {
    return AppShadows(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      brand: brand ?? this.brand,
    );
  }

  @override
  AppShadows lerp(AppShadows? other, double t) {
    if (other == null) return this;
    // BoxShadow.lerpList handles null gracefully
    return AppShadows(
      sm:    BoxShadow.lerpList(sm,    other.sm,    t) ?? sm,
      md:    BoxShadow.lerpList(md,    other.md,    t) ?? md,
      lg:    BoxShadow.lerpList(lg,    other.lg,    t) ?? lg,
      brand: BoxShadow.lerpList(brand, other.brand, t) ?? brand,
    );
  }
}

extension AppShadowsX on BuildContext {
  AppShadows get shadows => Theme.of(this).extension<AppShadows>()!;
}
