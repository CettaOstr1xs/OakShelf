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

  // Forest-night dark mode palette
  static const Color darkBackgroundColor = Color(0xFF0D1512);
  static const Color darkSurfaceColor = Color(0xFF17221C);
  static const Color darkPrimaryColor = Color(0xFF4EBE8B);
  static const Color moonlightColor = Color(0xFFC9D6EA);
  static const Color nightSandColor = Color(0xFF20293A);
  static const Color darkTextColor = Color(0xFFE6EEE9);
  static const Color darkTextMutedColor = Color(0xFF9AAFA4);
  static const Color darkOutlineColor = Color(0xFF28362E);

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        palette: const OakPalette.light(),
      );

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        palette: const OakPalette.dark(),
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required OakPalette palette,
  }) {
    final bool isLight = brightness == Brightness.light;
    final ColorScheme scheme = isLight
        ? const ColorScheme.light(
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
          )
        : const ColorScheme.dark(
            primary: darkPrimaryColor,
            onPrimary: Color(0xFF06231A),
            primaryContainer: Color(0xFF143728),
            onPrimaryContainer: Color(0xFFBFE9D2),
            secondary: Color(0xFF6FBEDF),
            onSecondary: Color(0xFF062330),
            secondaryContainer: Color(0xFF0F3548),
            onSecondaryContainer: Color(0xFFBFE3F2),
            tertiary: moonlightColor,
            onTertiary: Color(0xFF16202E),
            tertiaryContainer: nightSandColor,
            onTertiaryContainer: Color(0xFFE2EAF6),
            error: Color(0xFFCF6666),
            surface: darkSurfaceColor,
            onSurface: darkTextColor,
            onSurfaceVariant: darkTextMutedColor,
            outline: darkOutlineColor,
            outlineVariant: Color(0xFF1E2A23),
            shadow: Color(0xFF000000),
          );

    final Color textMain = scheme.onSurface;
    final Color textMuted = scheme.onSurfaceVariant;

    final base = isLight
        ? ThemeData.light(useMaterial3: true)
        : ThemeData.dark(useMaterial3: true);

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .copyWith(
          displayLarge: GoogleFonts.dmSerifDisplay(
            color: textMain,
            fontSize: 54,
            height: 1.04,
          ),
          displayMedium: GoogleFonts.dmSerifDisplay(
            color: textMain,
            fontSize: 42,
            height: 1.08,
          ),
          displaySmall: GoogleFonts.dmSerifDisplay(
            color: textMain,
            fontSize: 34,
            height: 1.08,
          ),
          headlineLarge: GoogleFonts.dmSerifDisplay(
            color: textMain,
            fontSize: 32,
            height: 1.12,
          ),
          headlineMedium: GoogleFonts.dmSerifDisplay(
            color: textMain,
            fontSize: 27,
            height: 1.15,
          ),
          headlineSmall: GoogleFonts.dmSerifDisplay(
            color: textMain,
            fontSize: 22,
            height: 1.2,
          ),
          titleLarge: GoogleFonts.plusJakartaSans(
            color: textMain,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          titleMedium: GoogleFonts.plusJakartaSans(
            color: textMain,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          titleSmall: GoogleFonts.plusJakartaSans(
            color: textMain,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: GoogleFonts.plusJakartaSans(
            color: textMain,
            fontSize: 16,
            height: 1.5,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            color: textMuted,
            fontSize: 14,
            height: 1.45,
          ),
          bodySmall: GoogleFonts.plusJakartaSans(
            color: textMuted,
            fontSize: 12,
            height: 1.4,
          ),
          labelLarge: GoogleFonts.plusJakartaSans(
            color: textMain,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          labelMedium: GoogleFonts.plusJakartaSans(
            color: textMuted,
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
      extensions: <ThemeExtension<dynamic>>{palette},
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 68,
        iconTheme: IconThemeData(color: scheme.onSurface),
        actionsIconTheme: IconThemeData(color: scheme.onSurface),
        titleTextStyle: GoogleFonts.dmSerifDisplay(
          color: scheme.onSurface,
          fontSize: 24,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest.withValues(
          alpha: isLight ? 1 : 0.6,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: palette.forestDeep.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest.withValues(
          alpha: isLight ? 1 : 0.6,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: textMuted.withValues(alpha: 0.72),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        prefixIconColor: scheme.primary,
        suffixIconColor: textMuted,
        border: inputBorder(scheme.outline),
        enabledBorder: inputBorder(scheme.outline),
        focusedBorder: inputBorder(scheme.primary, 1.5),
        errorBorder: inputBorder(scheme.error),
        focusedErrorBorder: inputBorder(scheme.error, 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.outline,
          disabledForegroundColor: textMuted,
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
          foregroundColor: scheme.primary,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          side: BorderSide(color: scheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.forestDeep,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 4,
        highlightElevation: 6,
        shape: const StadiumBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLowest.withValues(
          alpha: isLight ? 1 : 0.6,
        ),
        selectedColor: scheme.primary,
        disabledColor: scheme.outline,
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: textTheme.labelMedium!,
        secondaryLabelStyle: textTheme.labelMedium!.copyWith(
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest.withValues(
          alpha: isLight ? 1 : 0.95,
        ),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surface,
        modalBarrierColor: (isLight ? const Color(0x8A0B241B) : Colors.black)
            .withValues(alpha: 0.72),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor:
            isLight ? const Color(0xFFDDECE2) : scheme.outlineVariant,
        circularTrackColor:
            isLight ? const Color(0xFFDDECE2) : scheme.outlineVariant,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? palette.forestDeep : scheme.primaryContainer,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isLight
              ? Colors.white
              : (textTheme.titleSmall?.color ?? scheme.onSurface),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
        ),
      ),
    );
  }
}

/// Brand colors that flip between the day (sun/gold) and night (moon)
/// palettes. Access from any widget with `context.oak`.
@immutable
class OakPalette extends ThemeExtension<OakPalette> {
  /// Gold in light mode, moonlight silver-blue in dark mode.
  final Color accent;

  /// Deep icon color for chips/tints drawn on top of [accent]-tinted fills.
  final Color onAccent;
  final Color sand;
  final Color leaf;
  final Color ocean;
  final Color sky;
  final Color forestDeep;
  final Color backdropTop;
  final Color backdropMid;
  final Color backdropBottom;

  const OakPalette({
    required this.accent,
    required this.onAccent,
    required this.sand,
    required this.leaf,
    required this.ocean,
    required this.sky,
    required this.forestDeep,
    required this.backdropTop,
    required this.backdropMid,
    required this.backdropBottom,
  });

  const OakPalette.light()
      : this(
          accent: OakShelfTheme.accentGoldColor,
          onAccent: const Color(0xFF9A6D00),
          sand: OakShelfTheme.sandColor,
          leaf: OakShelfTheme.leafColor,
          ocean: OakShelfTheme.oceanBlueColor,
          sky: OakShelfTheme.skyColor,
          forestDeep: OakShelfTheme.forestDeep,
          backdropTop: const Color(0xFFF1FAF4),
          backdropMid: const Color(0xFFF9FBF4),
          backdropBottom: OakShelfTheme.backgroundColor,
        );

  const OakPalette.dark()
      : this(
          accent: OakShelfTheme.moonlightColor,
          onAccent: const Color(0xFF232E42),
          sand: OakShelfTheme.nightSandColor,
          leaf: const Color(0xFF86AE8C),
          ocean: const Color(0xFF6FBEDF),
          sky: const Color(0xFFA7D6E6),
          forestDeep: const Color(0xFF122019),
          backdropTop: OakShelfTheme.darkBackgroundColor,
          backdropMid: const Color(0xFF101A15),
          backdropBottom: const Color(0xFF0C1310),
        );

  @override
  OakPalette copyWith({
    Color? accent,
    Color? onAccent,
    Color? sand,
    Color? leaf,
    Color? ocean,
    Color? sky,
    Color? forestDeep,
    Color? backdropTop,
    Color? backdropMid,
    Color? backdropBottom,
  }) {
    return OakPalette(
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      sand: sand ?? this.sand,
      leaf: leaf ?? this.leaf,
      ocean: ocean ?? this.ocean,
      sky: sky ?? this.sky,
      forestDeep: forestDeep ?? this.forestDeep,
      backdropTop: backdropTop ?? this.backdropTop,
      backdropMid: backdropMid ?? this.backdropMid,
      backdropBottom: backdropBottom ?? this.backdropBottom,
    );
  }

  @override
  OakPalette lerp(ThemeExtension<OakPalette>? other, double t) {
    if (other is! OakPalette) return this;
    return OakPalette(
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      sand: Color.lerp(sand, other.sand, t)!,
      leaf: Color.lerp(leaf, other.leaf, t)!,
      ocean: Color.lerp(ocean, other.ocean, t)!,
      sky: Color.lerp(sky, other.sky, t)!,
      forestDeep: Color.lerp(forestDeep, other.forestDeep, t)!,
      backdropTop: Color.lerp(backdropTop, other.backdropTop, t)!,
      backdropMid: Color.lerp(backdropMid, other.backdropMid, t)!,
      backdropBottom: Color.lerp(backdropBottom, other.backdropBottom, t)!,
    );
  }

  @override
  Object get type => OakPalette;
}

extension OakPaletteContextX on BuildContext {
  OakPalette get oak => Theme.of(this).extension<OakPalette>()!;
}
