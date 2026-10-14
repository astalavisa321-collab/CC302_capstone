import 'package:flutter/material.dart';

class AppTheme {
  static const purple = Color(0xFF6D5AE6),
      green = Color(0xFF159A76),
      orange = Color(0xFFD97757),
      ink = Color(0xFF24233A),
      muted = Color(0xFF77768A),
      bg = Color(0xFFF7F7FB);
  static ThemeData get light => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme:
          ColorScheme.fromSeed(seedColor: purple).copyWith(primary: purple),
      appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: ink,
          elevation: 0,
          titleTextStyle:
              TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w800)),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE8E7F0))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE8E7F0))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: purple, width: 1.5))),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)))));
}
