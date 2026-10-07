import 'package:flutter/material.dart';

// Deep red and gold, matching the Ashoka-chakra icon; ivory background.
class AppColors {
  static const primary = Color(0xFFB4232E);     // deep red
  static const primaryDark = Color(0xFF8E1A24);
  static const bg = Color(0xFFFAF7F1);          // ivory
  static const card = Colors.white;
  static const text = Color(0xFF101322);
  static const text2 = Color(0xFF4B5265);
  static const text3 = Color(0xFF99A0B5);
  static const border = Color(0xFFE9E2D3);
  static const greenBg = Color(0xFFD7F5E3);
  static const greenFg = Color(0xFF065F46);
  static const amberBg = Color(0xFFFEF3C7);
  static const amberFg = Color(0xFF92400E);
  static const redBg = Color(0xFFFEE2E2);
  static const redFg = Color(0xFF991B1B);
  static const indigo = Color(0xFFC9A227);      // gold accent (name kept for call sites)
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
    ),
    fontFamily: 'Roboto',
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: const Color(0xFFF8E1E3),
      elevation: 0,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    ),
  );
}

// Status → badge colors (mirrors the web app's badge()).
({Color bg, Color fg}) statusColors(String? status) {
  final s = (status ?? '').toLowerCase();
  if (RegExp(r'paid|approved|credited').hasMatch(s)) {
    return (bg: AppColors.greenBg, fg: AppColors.greenFg);
  }
  if (RegExp(r'hold|stopped|pending').hasMatch(s)) {
    return (bg: AppColors.amberBg, fg: AppColors.amberFg);
  }
  if (RegExp(r'reject|cancel|terminat').hasMatch(s)) {
    return (bg: AppColors.redBg, fg: AppColors.redFg);
  }
  return (bg: const Color(0xFFEEF2FF), fg: AppColors.primaryDark);
}
