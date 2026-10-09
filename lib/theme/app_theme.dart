import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_shadows.dart';
import 'app_text_styles.dart';

/// Entry point for the RideLink theme.
///
/// Usage in main.dart:
///   MaterialApp(
///     theme: AppTheme.light,
///     darkTheme: AppTheme.dark,
///     themeMode: ThemeMode.system,
///   )
abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light, AppShadows.light, Brightness.light);
  static ThemeData get dark  => _build(AppColors.dark,  AppShadows.dark,  Brightness.dark);

  static ThemeData _build(AppColors c, AppShadows s, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness:      brightness,
      // Primary = brand amber
      primary:         c.brand500,
      onPrimary:       c.inkOnBrand,
      primaryContainer:   c.brand100,
      onPrimaryContainer: c.brand700,
      // Secondary = forest green
      secondary:       c.forest500,
      onSecondary:     c.inkOnForest,
      secondaryContainer:   c.forest100,
      onSecondaryContainer: c.forest700,
      // Tertiary = ride blue
      tertiary:        c.ride500,
      onTertiary:      Colors.white,
      tertiaryContainer:   c.ride100,
      onTertiaryContainer: c.ride500,
      // Error
      error:           c.statusError,
      onError:         isDark ? c.ink : Colors.white,
      errorContainer:  c.statusErrorTint,
      onErrorContainer: c.statusError,
      // Surface
      surface:         c.surfaceRaised,
      onSurface:       c.ink,
      surfaceContainerHighest: c.surfaceSunken,
      onSurfaceVariant: c.inkMuted,
      // Outline
      outline:         c.border,
      outlineVariant:  c.borderStrong,
      // Scrim
      scrim:           c.scrim,
      // Inverse
      inverseSurface:       isDark ? c.surfaceRaised : c.ink,
      onInverseSurface:     isDark ? c.ink : c.surfaceRaised,
      inversePrimary:       isDark ? c.brand700 : c.brand300,
      shadow:          const Color(0xFF000000),
    );

    final textTheme = TextTheme(
      displayLarge:  AppTextStyles.displayXl,
      displayMedium: AppTextStyles.displayLg,
      displaySmall:  AppTextStyles.displayMd,
      headlineLarge: AppTextStyles.displayMd,
      headlineMedium:AppTextStyles.displaySm,
      headlineSmall: AppTextStyles.displaySm,
      titleLarge:    AppTextStyles.labelLg,
      titleMedium:   AppTextStyles.label,
      titleSmall:    AppTextStyles.labelSm,
      bodyLarge:     AppTextStyles.bodyLg,
      bodyMedium:    AppTextStyles.body,
      bodySmall:     AppTextStyles.bodySm,
      labelLarge:    AppTextStyles.labelLg,
      labelMedium:   AppTextStyles.label,
      labelSmall:    AppTextStyles.labelSm,
    ).apply(
      bodyColor:    c.ink,
      displayColor: c.ink,
    );

    return ThemeData(
      useMaterial3:   true,
      brightness:     brightness,
      colorScheme:    colorScheme,
      scaffoldBackgroundColor: c.surface,
      textTheme:      textTheme,

      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor:    c.surfaceRaised,
        foregroundColor:    c.ink,
        surfaceTintColor:   Colors.transparent,
        elevation:          0,
        shadowColor:        Colors.transparent,
        titleTextStyle:     AppTextStyles.displaySm.copyWith(color: c.ink),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:      c.surfaceRaised,
        selectedItemColor:    c.brand500,
        unselectedItemColor:  c.inkMuted,
        selectedLabelStyle:   AppTextStyles.labelSm,
        unselectedLabelStyle: AppTextStyles.labelSm,
        elevation:            0,
        type: BottomNavigationBarType.fixed,
      ),

      // Cards
      cardTheme: CardThemeData(
        color:        c.surfaceRaised,
        elevation:    0,
        shadowColor:  Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated buttons = primary CTA
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.brand500,
          foregroundColor: c.inkOnBrand,
          minimumSize:     const Size(double.infinity, AppLayout.minTapTarget),
          padding:         const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
          textStyle:       AppTextStyles.labelLg,
          elevation:       0,
          shadowColor:     Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      // Outlined buttons = secondary actions
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          minimumSize:     const Size(double.infinity, AppLayout.minTapTarget),
          padding:         const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
          textStyle:       AppTextStyles.labelLg,
          side:            BorderSide(color: c.borderStrong, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      // Text buttons = ghost actions
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.brand500,
          textStyle:       AppTextStyles.labelLg,
          minimumSize:     const Size(44, AppLayout.minTapTarget),
          padding:         const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled:          true,
        fillColor:       c.surfaceSunken,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide:   BorderSide(color: c.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide:   BorderSide(color: c.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide:   BorderSide(color: c.borderFocus, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide:   BorderSide(color: c.statusError, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        hintStyle:  AppTextStyles.body.copyWith(color: c.inkFaint),
        labelStyle: AppTextStyles.labelLg.copyWith(color: c.inkMuted),
        floatingLabelStyle: AppTextStyles.labelSm.copyWith(color: c.brand500),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor:   c.surfaceSunken,
        selectedColor:     c.brand100,
        labelStyle:        AppTextStyles.label.copyWith(color: c.inkMuted),
        side:              BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color:     c.border,
        thickness: 1,
        space:     1,
      ),

      // Icon
      iconTheme:         IconThemeData(color: c.ink, size: 24),
      primaryIconTheme:  IconThemeData(color: c.inkOnBrand, size: 24),

      // Page transitions — fast (150ms ease-out per design system)
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        },
      ),

      // Custom design-system extensions
      extensions: [c, s],
    );
  }
}
