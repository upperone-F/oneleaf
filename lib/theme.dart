import 'package:flutter/material.dart';

/// 极简清新配色（承接原型：米白 + 薄荷绿 + 暖粉 + 雾蓝）。
class AppTheme {
  static const Color paper = Color(0xFFF8F7F1);      // 米白底
  static const Color card = Color(0xFFFFFFFF);        // 卡片白
  static const Color mint = Color(0xFF85BAA5);        // 薄荷绿（主色）
  static const Color mintDark = Color(0xFF5E9A83);
  static const Color blush = Color(0xFFE5B0B7);       // 暖粉
  static const Color mist = Color(0xFFB9CDD6);        // 雾蓝
  static const Color gold = Color(0xFFE0C08A);        // 暖金
  static const Color ink = Color(0xFF4A4A47);         // 主文字
  static const Color inkSoft = Color(0xFF9A9A94);     // 次文字
  static const Color line = Color(0xFFEAE8DF);        // 分隔线

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: mint,
        primary: mint,
        surface: card,
      ),
      fontFamily: null,
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        surfaceTintColor: paper,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: ink),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: ink, fontSize: 15, height: 1.6),
        bodySmall: TextStyle(color: inkSoft, fontSize: 13, height: 1.5),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.all(18),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: mint,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
