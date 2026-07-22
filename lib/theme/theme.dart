import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BookeryTheme {
  // Theme Color Palette
  static const Color primaryColor = Color(0xFFE07A5F); // Terracotta / Warm Amber
  static const Color backgroundColor = Color(0xFFFDFBF7); // Soft Cream / Off-White
  static const Color surfaceColor = Colors.white; // Crisp White
  static const Color textDarkColor = Color(0xFF2F3E46); // Deep Charcoal / Dark Espresso
  static const Color textMutedColor = Color(0xFF6D818A); // Slate Gray
  static const Color accentGoldColor = Color(0xFFF2CC8F); // Warm Gold for ratings

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        background: backgroundColor,
        surface: surfaceColor,
        onBackground: textDarkColor,
        onSurface: textDarkColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDarkColor),
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: textDarkColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shadowColor: textDarkColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          color: textDarkColor,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          color: textDarkColor,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          color: textDarkColor,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: GoogleFonts.playfairDisplay(
          color: textDarkColor,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          color: textDarkColor,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        headlineSmall: GoogleFonts.playfairDisplay(
          color: textDarkColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          color: textDarkColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        titleMedium: GoogleFonts.inter(
          color: textDarkColor,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleSmall: GoogleFonts.inter(
          color: textDarkColor,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textDarkColor,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textMutedColor,
          fontSize: 14,
        ),
        bodySmall: GoogleFonts.inter(
          color: textMutedColor,
          fontSize: 12,
        ),
      ),
    );
  }
}
