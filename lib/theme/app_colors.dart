import 'package:flutter/material.dart';

/// All color tokens from the RideLink design system (tokens.json).
/// Access via BuildContext: `context.colors.brand500`
/// Never hardcode a hex value in UI code — use this class instead.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    // Brand amber
    required this.brand100,
    required this.brand300,
    required this.brand500,
    required this.brand700,
    // Forest green
    required this.forest100,
    required this.forest500,
    required this.forest700,
    // Ride blue
    required this.ride100,
    required this.ride500,
    // Errand purple
    required this.errand100,
    required this.errand500,
    // Surfaces
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.surfaceOverlay,
    // Ink
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.inkOnBrand,
    required this.inkOnForest,
    // Borders
    required this.border,
    required this.borderStrong,
    required this.borderFocus,
    // Status
    required this.statusSuccess,
    required this.statusWarning,
    required this.statusError,
    required this.statusErrorTint,
    required this.statusInfo,
    required this.statusNeutral,
    // Special
    required this.countdown,
    required this.scrim,
  });

  final Color brand100;
  final Color brand300;
  final Color brand500;
  final Color brand700;

  final Color forest100;
  final Color forest500;
  final Color forest700;

  final Color ride100;
  final Color ride500;

  final Color errand100;
  final Color errand500;

  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color surfaceOverlay;

  final Color ink;
  final Color inkMuted;
  final Color inkFaint;
  final Color inkOnBrand;
  final Color inkOnForest;

  final Color border;
  final Color borderStrong;
  final Color borderFocus;

  final Color statusSuccess;
  final Color statusWarning;
  final Color statusError;
  final Color statusErrorTint;
  final Color statusInfo;
  final Color statusNeutral;

  final Color countdown;
  final Color scrim;

  // ── Light theme ──────────────────────────────────────────────────────────
  static const light = AppColors(
    brand100:        Color(0xFFFDF0E6),
    brand300:        Color(0xFFE8842A),
    brand500:        Color(0xFFC05818),
    brand700:        Color(0xFF8C3E0E),

    forest100:       Color(0xFFE6F4EC),
    forest500:       Color(0xFF1B6B45),
    forest700:       Color(0xFF134D32),

    ride100:         Color(0xFFE3EDF8),
    ride500:         Color(0xFF1565C0),

    errand100:       Color(0xFFF0EAF8),
    errand500:       Color(0xFF6B3FA0),

    surface:         Color(0xFFF7F7F5),
    surfaceRaised:   Color(0xFFFFFFFF),
    surfaceSunken:   Color(0xFFEDEDE8),
    surfaceOverlay:  Color(0xFFFFFFFF),

    ink:             Color(0xFF111318),
    inkMuted:        Color(0xFF5C6172),
    inkFaint:        Color(0xFF929AA8),
    inkOnBrand:      Color(0xFF111318),  // amber never holds white text
    inkOnForest:     Color(0xFFFFFFFF),

    border:          Color(0xFFDDE0E8),
    borderStrong:    Color(0xFFA8AFC0),
    borderFocus:     Color(0xFFC05818),

    statusSuccess:   Color(0xFF1B6B45),
    statusWarning:   Color(0xFFC05818),
    statusError:     Color(0xFFC02828),
    statusErrorTint: Color(0xFFFCE8E8),
    statusInfo:      Color(0xFF1565C0),
    statusNeutral:   Color(0xFF5C6172),

    countdown:       Color(0xFFB83000),
    scrim:           Color(0x66000000),
  );

  // ── Dark theme ───────────────────────────────────────────────────────────
  static const dark = AppColors(
    brand100:        Color(0xFF2D1808),
    brand300:        Color(0xFFE8842A),
    brand500:        Color(0xFFF08030),
    brand700:        Color(0xFFC05818),

    forest100:       Color(0xFF0A1F14),
    forest500:       Color(0xFF22A85A),
    forest700:       Color(0xFF1B8040),

    ride100:         Color(0xFF0A1828),
    ride500:         Color(0xFF4D94E8),

    errand100:       Color(0xFF1A0F28),
    errand500:       Color(0xFF9B6FD0),

    surface:         Color(0xFF0F1318),
    surfaceRaised:   Color(0xFF1A1F2B),
    surfaceSunken:   Color(0xFF080B0F),
    surfaceOverlay:  Color(0xFF242933),

    ink:             Color(0xFFF0F1F5),
    inkMuted:        Color(0xFF9499A8),
    inkFaint:        Color(0xFF545A66),
    inkOnBrand:      Color(0xFF111318),  // always dark in both themes
    inkOnForest:     Color(0xFF111318),  // brighter green needs dark text

    border:          Color(0xFF28303F),
    borderStrong:    Color(0xFF3D4658),
    borderFocus:     Color(0xFFF08030),

    statusSuccess:   Color(0xFF22A85A),
    statusWarning:   Color(0xFFF08030),
    statusError:     Color(0xFFFF4444),
    statusErrorTint: Color(0xFF2D0A0A),
    statusInfo:      Color(0xFF4D94E8),
    statusNeutral:   Color(0xFF9499A8),

    countdown:       Color(0xFFFF5520),
    scrim:           Color(0x99000000),
  );

  @override
  AppColors copyWith({
    Color? brand100, Color? brand300, Color? brand500, Color? brand700,
    Color? forest100, Color? forest500, Color? forest700,
    Color? ride100, Color? ride500,
    Color? errand100, Color? errand500,
    Color? surface, Color? surfaceRaised, Color? surfaceSunken, Color? surfaceOverlay,
    Color? ink, Color? inkMuted, Color? inkFaint, Color? inkOnBrand, Color? inkOnForest,
    Color? border, Color? borderStrong, Color? borderFocus,
    Color? statusSuccess, Color? statusWarning, Color? statusError,
    Color? statusErrorTint, Color? statusInfo, Color? statusNeutral,
    Color? countdown, Color? scrim,
  }) {
    return AppColors(
      brand100: brand100 ?? this.brand100,
      brand300: brand300 ?? this.brand300,
      brand500: brand500 ?? this.brand500,
      brand700: brand700 ?? this.brand700,
      forest100: forest100 ?? this.forest100,
      forest500: forest500 ?? this.forest500,
      forest700: forest700 ?? this.forest700,
      ride100: ride100 ?? this.ride100,
      ride500: ride500 ?? this.ride500,
      errand100: errand100 ?? this.errand100,
      errand500: errand500 ?? this.errand500,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      inkOnBrand: inkOnBrand ?? this.inkOnBrand,
      inkOnForest: inkOnForest ?? this.inkOnForest,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      borderFocus: borderFocus ?? this.borderFocus,
      statusSuccess: statusSuccess ?? this.statusSuccess,
      statusWarning: statusWarning ?? this.statusWarning,
      statusError: statusError ?? this.statusError,
      statusErrorTint: statusErrorTint ?? this.statusErrorTint,
      statusInfo: statusInfo ?? this.statusInfo,
      statusNeutral: statusNeutral ?? this.statusNeutral,
      countdown: countdown ?? this.countdown,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      brand100: Color.lerp(brand100, other.brand100, t)!,
      brand300: Color.lerp(brand300, other.brand300, t)!,
      brand500: Color.lerp(brand500, other.brand500, t)!,
      brand700: Color.lerp(brand700, other.brand700, t)!,
      forest100: Color.lerp(forest100, other.forest100, t)!,
      forest500: Color.lerp(forest500, other.forest500, t)!,
      forest700: Color.lerp(forest700, other.forest700, t)!,
      ride100: Color.lerp(ride100, other.ride100, t)!,
      ride500: Color.lerp(ride500, other.ride500, t)!,
      errand100: Color.lerp(errand100, other.errand100, t)!,
      errand500: Color.lerp(errand500, other.errand500, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      inkOnBrand: Color.lerp(inkOnBrand, other.inkOnBrand, t)!,
      inkOnForest: Color.lerp(inkOnForest, other.inkOnForest, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      statusSuccess: Color.lerp(statusSuccess, other.statusSuccess, t)!,
      statusWarning: Color.lerp(statusWarning, other.statusWarning, t)!,
      statusError: Color.lerp(statusError, other.statusError, t)!,
      statusErrorTint: Color.lerp(statusErrorTint, other.statusErrorTint, t)!,
      statusInfo: Color.lerp(statusInfo, other.statusInfo, t)!,
      statusNeutral: Color.lerp(statusNeutral, other.statusNeutral, t)!,
      countdown: Color.lerp(countdown, other.countdown, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
