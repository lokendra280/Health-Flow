import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Brand Palette ────────────────────────────────────────────────────────────
class AppColors {
  static const green900 = Color(0xFF1B4332);
  static const green700 = Color(0xFF2D6A4F);
  static const green500 = Color(0xFF52B788);
  static const green200 = Color(0xFF95D5B2);
  static const green100 = Color(0xFFD8F3DC);
  static const amber700 = Color(0xFFB45309);
  static const amber400 = Color(0xFFFBBF24);
  static const amber100 = Color(0xFFFEF3C7);
  static const coral700 = Color(0xFFC84B31);
  static const coral100 = Color(0xFFFFEDE8);
  static const purple700 = Color(0xFF6D28D9);
  static const purple100 = Color(0xFFEDE9FE);
  static const blue700 = Color(0xFF1D4ED8);
  static const blue100 = Color(0xFFDBEAFE);
  static const rose700 = Color(0xFFBE185D);
  static const rose100 = Color(0xFFFFE4E6);
  static const teal700 = Color(0xFF0F766E);
  static const teal100 = Color(0xFFCCFBF1);
  static const indigo700 = Color(0xFF4338CA);
  static const indigo100 = Color(0xFFE0E7FF);

  static const List<Color> habitPalette = [
    green700,
    amber700,
    blue700,
    purple700,
    coral700,
    teal700,
    indigo700,
    rose700,
  ];
}

// ─── Theme Builder ────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final bg = dark ? const Color(0xFF0E0E0D) : const Color(0xFFF5F4F0);
    final surface = dark ? const Color(0xFF1A1A18) : Colors.white;
    final accent = dark ? AppColors.green500 : AppColors.green700;

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.green700,
        brightness: b,
        primary: accent,
        surface: surface,
        background: bg,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.dmSansTextTheme().apply(
        bodyColor: dark ? const Color(0xFFF0EDE6) : const Color(0xFF1A1917),
        displayColor: dark ? const Color(0xFFF0EDE6) : const Color(0xFF1A1917),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(
            color: dark ? const Color(0xFFF0EDE6) : const Color(0xFF1A1917)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: dark ? const Color(0x12FFFFFF) : const Color(0x14000000),
            width: 1.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF242422) : const Color(0xFFF0EEE8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: dark ? const Color(0x1FFFFFFF) : const Color(0x20000000),
              width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: dark ? const Color(0x1FFFFFFF) : const Color(0x20000000),
              width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.dmSans(
          color: dark ? const Color(0xFF5E5C57) : const Color(0xFFA09D98),
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
            (s) => s.contains(MaterialState.selected) ? accent : null),
        trackColor: MaterialStateProperty.resolveWith((s) =>
            s.contains(MaterialState.selected)
                ? accent.withOpacity(0.3)
                : null),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        thumbColor: accent,
        inactiveTrackColor: accent.withOpacity(0.2),
      ),
    );
  }
}

// ─── Context Extensions ───────────────────────────────────────────────────────
extension ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bgColor =>
      isDark ? const Color(0xFF0E0E0D) : const Color(0xFFF5F4F0);
  Color get surfaceColor => isDark ? const Color(0xFF1A1A18) : Colors.white;
  Color get surface2 =>
      isDark ? const Color(0xFF242422) : const Color(0xFFF0EEE8);
  Color get surface3 =>
      isDark ? const Color(0xFF2E2E2B) : const Color(0xFFE8E5DE);
  Color get textPrimary =>
      isDark ? const Color(0xFFF0EDE6) : const Color(0xFF1A1917);
  Color get textSecondary =>
      isDark ? const Color(0xFF9B9790) : const Color(0xFF6B6860);
  Color get textTertiary =>
      isDark ? const Color(0xFF5E5C57) : const Color(0xFFA09D98);
  Color get borderColor =>
      isDark ? const Color(0x12FFFFFF) : const Color(0x14000000);
  Color get border2 =>
      isDark ? const Color(0x1FFFFFFF) : const Color(0x24000000);
  Color get accent => isDark ? AppColors.green500 : AppColors.green700;
  Color get red => isDark
      ? const Color.fromARGB(255, 211, 111, 23)
      : const Color(0xFFDC2626);

  Color get accentSurf => isDark ? const Color(0xFF1B4332) : AppColors.green100;
  Color get accentText => isDark ? const Color(0xFF95D5B2) : AppColors.green900;
  Color get pillBg =>
      isDark ? const Color(0xFFF0EDE6) : const Color(0xFF1A1917);
  Color get pillFg =>
      isDark ? const Color(0xFF111110) : const Color(0xFFF7F6F2);

  TextStyle syne(double size, FontWeight w, {Color? color}) => GoogleFonts.syne(
      fontSize: size, fontWeight: w, color: color ?? textPrimary);
  TextStyle dmSans(double size, FontWeight w, {Color? color}) =>
      GoogleFonts.dmSans(
          fontSize: size, fontWeight: w, color: color ?? textPrimary);
}
