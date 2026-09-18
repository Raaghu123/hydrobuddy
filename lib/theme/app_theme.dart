import 'package:flutter/material.dart';

class AppTheme {
  static const Color aqua = Color(0xFF00C2FF);
  static const Color deepBlue = Color(0xFF1B2CC1);
  static const Color sunny = Color(0xFFFFC42E);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color mint = Color(0xFF4ADE80);
  static const Color bgLight = Color(0xFFF0F9FF);
  static const Color cardDark = Color(0xFF1E293B);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: aqua,
        primary: deepBlue,
        secondary: aqua,
        tertiary: sunny,
      ),
      scaffoldBackgroundColor: bgLight,
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
            fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -0.5),
        titleLarge:
            const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
      ),
    );
  }
}
