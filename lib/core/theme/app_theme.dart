import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de color de DESIGN.md. Un solo acento (menta), fondo gris calido,
/// tarjetas blancas, negro para navegacion/enfasis.
abstract final class AppColors {
  static const background = Color(0xFFF1F1EE);
  static const surface = Color(0xFFFFFFFF);
  static const accent = Color(0xFF8FD9C4);
  static const accentStrong = Color(0xFF4FAE93);
  static const ink = Color(0xFF181818);
  static const inkSoft = Color(0xFF4A4A4A);
  static const onInk = Color(0xFFFFFFFF);
  static const borderSubtle = Color(0xFFE7E7E3);
  static const error = Color(0xFFD64545);
}

/// Radios de DESIGN.md.
abstract final class AppRadius {
  static const card = 24.0;
  static const chip = 999.0;
}

/// Espaciado de DESIGN.md.
abstract final class AppSpacing {
  static const page = 20.0;
  static const card = 16.0;
  static const stack = 12.0;
}

ThemeData buildAppTheme() {
  final textTheme = GoogleFonts.poppinsTextTheme().copyWith(
    displayMedium: GoogleFonts.poppins(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    ),
    titleLarge: GoogleFonts.poppins(
      fontSize: 21,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
    titleMedium: GoogleFonts.poppins(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    ),
    bodyMedium: GoogleFonts.poppins(fontSize: 14, color: AppColors.ink),
    bodySmall: GoogleFonts.poppins(fontSize: 14, color: AppColors.inkSoft),
    labelSmall: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.inkSoft,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.ink,
      onPrimary: AppColors.onInk,
      secondary: AppColors.accent,
      onSecondary: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.error,
      onError: AppColors.onInk,
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.ink,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.onInk,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.accentStrong, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      labelStyle: GoogleFonts.poppins(color: AppColors.inkSoft),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accentStrong,
    ),
  );
}
