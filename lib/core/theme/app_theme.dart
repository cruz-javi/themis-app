import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de color oficiales de Themis (docs/brand).
/// Paleta basada en Ink oscuro (#0F172A), Fondo Slate (#F8FAFC),
/// y Acento Esmeralda/Teal (#12B39B).
abstract final class AppColors {
  // Brand Base
  static const ink = Color(0xFF0F172A); // Slate 900
  static const inkSoft = Color(0xFF475569); // Slate 600
  static const inkMuted = Color(0xFF94A3B8); // Slate 400
  static const onInk = Color(0xFFFFFFFF);

  // Background & Surface
  static const background = Color(0xFFF8FAFC); // Slate 50
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F5F9); // Slate 100

  // Brand Accent (Themis Emerald / Teal)
  static const accent = Color(0xFF12B39B);
  static const accentStrong = Color(0xFF0D9488); // Teal 600
  static const accentLight = Color(0xFFE6F7F5); // Light mint tint
  static const onAccent = Color(0xFFFFFFFF);

  // Borders
  static const borderSubtle = Color(0xFFE2E8F0); // Slate 200
  static const borderMedium = Color(0xFFCBD5E1); // Slate 300

  // Semantic Status
  static const error = Color(0xFFEF4444); // Red 500
  static const errorLight = Color(0xFFFEF2F2); // Red 50
  static const success = Color(0xFF10B981); // Emerald 500
  static const successLight = Color(0xFFECFDF5); // Emerald 50
  static const warning = Color(0xFFF59E0B); // Amber 500
  static const warningLight = Color(0xFFFFFBEB); // Amber 50
  static const info = Color(0xFF3B82F6); // Blue 500
  static const infoLight = Color(0xFFEFF6FF); // Blue 50
}

/// Sistema de espaciado estricto basado en regla de 8px.
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 40.0;
  static const double xxxl = 48.0;

  // Semantic Layout Spacings
  static const double page = 24.0;
  static const double card = 16.0;
  static const double cardPadding = 20.0;
  static const double gap = 12.0;
}

/// Radios de curvatura modernos y consistentes.
abstract final class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double card = 18.0;
  static const double button = 14.0;
  static const double chip = 999.0;
}

/// Sombras sutiles y elegantes.
abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x050F172A),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x120F172A),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}

ThemeData buildAppTheme() {
  final baseTextTheme = GoogleFonts.interTextTheme();

  final textTheme = baseTextTheme.copyWith(
    displayLarge: GoogleFonts.plusJakartaSans(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: AppColors.ink,
    ),
    displayMedium: GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: AppColors.ink,
    ),
    headlineMedium: GoogleFonts.plusJakartaSans(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: AppColors.ink,
    ),
    titleLarge: GoogleFonts.plusJakartaSans(
      fontSize: 19,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: AppColors.ink,
    ),
    titleMedium: GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
    titleSmall: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: AppColors.ink,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: AppColors.ink,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.35,
      color: AppColors.inkSoft,
    ),
    labelLarge: GoogleFonts.plusJakartaSans(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.inkSoft,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      color: AppColors.inkMuted,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.ink,
      onPrimary: AppColors.onInk,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceContainerHighest: AppColors.surfaceVariant,
      error: AppColors.error,
      onError: AppColors.onInk,
      outline: AppColors.borderSubtle,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.ink,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: const IconThemeData(color: AppColors.ink),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.borderSubtle, width: 1),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.onInk,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: Colors.transparent,
        elevation: 0,
        side: const BorderSide(color: AppColors.borderMedium, width: 1.2),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
      labelStyle: GoogleFonts.inter(
        color: AppColors.inkSoft,
        fontSize: 14,
      ),
      floatingLabelStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: GoogleFonts.inter(
        color: AppColors.inkMuted,
        fontSize: 14,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accentStrong,
    ),
  );
}
