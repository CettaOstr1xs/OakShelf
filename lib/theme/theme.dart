import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OakShelfTheme {
  static const Color primaryColor = Color(0xFF176B4D);
  static const Color forestDeep = Color(0xFF0B3D2E);
  static const Color leafColor = Color(0xFF6F9F63);
  static const Color oceanBlueColor = Color(0xFF1677A6);
  static const Color skyColor = Color(0xFF8ED4E8);
  static const Color accentGoldColor = Color(0xFFF4C44E);
  static const Color sandColor = Color(0xFFFFF4D6);
  static const Color backgroundColor = Color(0xFFF5FAF4);
  static const Color surfaceColor = Color(0xFFFFFEFA);
  static const Color textDarkColor = Color(0xFF10231C);
  static const Color textMutedColor = Color(0xFF52645D);
  static const Color outlineColor = Color(0xFFD8E5DC);
  static const Color errorColor = Color(0xFFBA3B3B);

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    const scheme = ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD8F2E3),
      onPrimaryContainer: forestDeep,
      secondary: oceanBlueColor,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD8F1FA),
      onSecondaryContainer: Color(0xFF0A415D),
      tertiary: accentGoldColor,
      onTertiary: textDarkColor,
      tertiaryContainer: sandColor,
      onTertiaryContainer: Color(0xFF4F3B00),
      error: errorColor,
      surface: surfaceColor,
      onSurface: textDarkColor,
      onSurfaceVariant: textMutedColor,
      outline: outlineColor,
      outlineVariant: Color(0xFFE8F0EA),
      shadow: Color(0xFF14372B),
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .copyWith(
          displayLarge: GoogleFonts.dmSerifDisplay(
            color: textDarkColor,
            fontSize: 54,
            height: 1.04,
          ),
          displayMedium: GoogleFonts.dmSerifDisplay(
            color: textDarkColor,
            fontSize: 42,
            height: 1.08,
          ),
          displaySmall: GoogleFonts.dmSerifDisplay(
            color: textDarkColor,
            fontSize: 34,
            height: 1.08,
          ),
          headlineLarge: GoogleFonts.dmSerifDisplay(
            color: textDarkColor,
            fontSize: 32,
            height: 1.12,
          ),
          headlineMedium: GoogleFonts.dmSerifDisplay(
            color: textDarkColor,
            fontSize: 27,
            height: 1.15,
          ),
          headlineSmall: GoogleFonts.dmSerifDisplay(
            color: textDarkColor,
            fontSize: 22,
            height: 1.2,
          ),
          titleLarge: GoogleFonts.plusJakartaSans(
            color: textDarkColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          titleMedium: GoogleFonts.plusJakartaSans(
            color: textDarkColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          titleSmall: GoogleFonts.plusJakartaSans(
            color: textDarkColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: GoogleFonts.plusJakartaSans(
            color: textDarkColor,
            fontSize: 16,
            height: 1.5,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            color: textMutedColor,
            fontSize: 14,
            height: 1.45,
          ),
          bodySmall: GoogleFonts.plusJakartaSans(
            color: textMutedColor,
            fontSize: 12,
            height: 1.4,
          ),
          labelLarge: GoogleFonts.plusJakartaSans(
            color: textDarkColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          labelMedium: GoogleFonts.plusJakartaSans(
            color: textMutedColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 68,
        iconTheme: const IconThemeData(color: textDarkColor),
        actionsIconTheme: const IconThemeData(color: textDarkColor),
        titleTextStyle: GoogleFonts.dmSerifDisplay(
          color: textDarkColor,
          fontSize: 24,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: forestDeep.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: outlineColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: textMutedColor.withValues(alpha: 0.72),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        prefixIconColor: primaryColor,
        suffixIconColor: textMutedColor,
        border: inputBorder(outlineColor),
        enabledBorder: inputBorder(outlineColor),
        focusedBorder: inputBorder(primaryColor, 1.5),
        errorBorder: inputBorder(errorColor),
        focusedErrorBorder: inputBorder(errorColor, 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: outlineColor,
          disabledForegroundColor: textMutedColor,
          elevation: 0,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: forestDeep,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 4,
        highlightElevation: 6,
        shape: StadiumBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primaryColor,
        disabledColor: outlineColor,
        side: const BorderSide(color: outlineColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: textTheme.labelMedium!,
        secondaryLabelStyle: textTheme.labelMedium!.copyWith(
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surfaceColor,
        modalBarrierColor: Color(0x8A0B241B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: outlineColor,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: Color(0xFFDDECE2),
        circularTrackColor: Color(0xFFDDECE2),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: forestDeep,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : textMutedColor,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primaryColor
              : outlineColor,
        ),
      ),
    );
  }
}
