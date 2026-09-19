import 'package:flutter/material.dart';

/// Hydrify-inspired theme: fresh water blue, deep navy ink,
/// soft ice-blue surfaces, chunky 24px cards.
class AppTheme {
  static const Color primary = Color(0xFF1E9BF3);
  static const Color primaryDark = Color(0xFF0B6BC0);
  static const Color sky = Color(0xFF5AB8FF);
  static const Color ink = Color(0xFF0A2540);
  static const Color muted = Color(0xFF6B7C93);
  static const Color bg = Color(0xFFEDF4F9);
  static const Color tile = Color(0xFFE3F1FD);
  static const Color amber = Color(0xFFFFB020);
  static const Color amberBg = Color(0xFFFFF3D9);
  static const Color green = Color(0xFF22C55E);
  static const Color navyCard = Color(0xFF0E2A47);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: sky,
        tertiary: amber,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            color: ink, fontWeight: FontWeight.w800, fontSize: 22),
        iconTheme: IconThemeData(color: ink),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: tile,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary);
          }
          return const IconThemeData(color: muted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: primary);
          }
          return const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: muted);
        }),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: base.textTheme.copyWith(
        headlineLarge: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 34,
            letterSpacing: -0.5,
            color: ink),
        headlineMedium: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 24, color: ink),
        titleLarge:
            const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: ink),
        titleMedium:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: ink),
        bodyMedium: const TextStyle(color: ink),
        bodySmall: const TextStyle(color: muted),
      ),
    );
  }
}
