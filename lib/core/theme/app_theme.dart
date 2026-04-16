import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF00C896);
  static const secondary = Color(0xFF6C63FF);
  static const bg = Color(0xFF0F1117);
  static const card = Color(0xFF1A1D26);
  static const cardAlt = Color(0xFF22263A);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        primaryColor: primary,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: card,
          background: bg,
        ),
        cardTheme: CardThemeData(
          color: card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          elevation: 0,
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: card,
          selectedItemColor: primary,
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
              color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
          headlineMedium: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: Colors.white70, fontSize: 15),
          bodyMedium: TextStyle(color: Colors.white60, fontSize: 14),
          labelLarge: TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: card,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          labelStyle: const TextStyle(color: Colors.white54),
          hintStyle: const TextStyle(color: Colors.white30),
        ),
      );
}
