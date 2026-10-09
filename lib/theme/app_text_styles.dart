import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens from the RideLink design system (tokens.json).
///
/// Fonts: Poppins (display/headings) + DM Sans (body/UI) + system mono.
/// Requires `google_fonts: ^6.2.1` in pubspec.yaml.
///
/// Usage:
///   Text('RideLink', style: AppTextStyles.displayXl)
///   Text('KES 214', style: AppTextStyles.displaySm.copyWith(color: ...))
abstract final class AppTextStyles {
  // ── Display (Poppins) ────────────────────────────────────────────────────

  /// 32 / 38 — hero headings, splash screens, welcome.
  static TextStyle get displayXl => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 38 / 32,
    letterSpacing: -0.5,
  );

  /// 26 / 32 — screen titles, empty-state headings.
  static TextStyle get displayLg => GoogleFonts.poppins(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 32 / 26,
    letterSpacing: -0.3,
  );

  /// 22 / 28 — section headers, card headlines, rider profile name.
  static TextStyle get displayMd => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
  );

  /// 18 / 24 — sub-section heads, dialog titles, amount displays.
  static TextStyle get displaySm => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
  );

  // ── Body + UI (DM Sans) ──────────────────────────────────────────────────

  /// 17 / 26 — primary body copy, order descriptions.
  static TextStyle get bodyLg => GoogleFonts.dmSans(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 26 / 17,
  );

  /// 15 / 22 — default UI text: list items, form field values.
  static TextStyle get body => GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 22 / 15,
  );

  /// 13 / 18 — captions, timestamps, helper text.
  static TextStyle get bodySm => GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
  );

  /// 15 / 20 — button labels, form labels, prominent nav items.
  static TextStyle get labelLg => GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 20 / 15,
  );

  /// 13 / 18 — chips, badges, tab labels, small action buttons.
  static TextStyle get label => GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 18 / 13,
  );

  /// 11 / 16 — micro-labels, icon legends, status dot labels.
  static TextStyle get labelSm => GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 16 / 11,
  );

  // ── Mono ─────────────────────────────────────────────────────────────────

  /// 13 / 18 — KES amounts in ledger/receipt views, order IDs, hash previews.
  /// Signals machine-precision; aids scanning of long numeric strings.
  static const TextStyle mono = TextStyle(
    fontFamily: 'Courier New',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
  );
}
