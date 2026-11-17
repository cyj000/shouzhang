import 'package:flutter/material.dart';

/// 手绘风 Design Token（PKG-01）。
///
/// 暖色纸张质感 + 手写感字体 + 大圆角控件，统一在此定义，禁止散落魔法值。
abstract final class AppTheme {
  // —— 纸张 / 墨色 ——
  static const Color paper = Color(0xFFFBF6EC);
  static const Color paperDark = Color(0xFF2B2926);
  static const Color ink = Color(0xFF3B332B);
  static const Color inkSoft = Color(0xFF7A6E61);
  static const Color accent = Color(0xFFC96F53); // 朱砂
  static const Color accentDark = Color(0xFFD98F73);
  static const Color income = Color(0xFF4F8A6B);
  static const Color expense = Color(0xFFC0573F);

  // —— 间距（4pt 栅格）——
  static const double spaceXS = 4;
  static const double spaceS = 8;
  static const double spaceM = 16;
  static const double spaceL = 24;
  static const double spaceXL = 32;

  // —— 圆角 ——
  static const double radiusS = 8;
  static const double radiusM = 16;
  static const double radiusL = 28;

  /// 手写感字体族：优先系统手写体，缺失时回退系统默认（一期不内置字体文件）。
  static const String handFontFamily = 'Segoe Print';

  static ThemeData light() => _build(
        brightness: Brightness.light,
        background: paper,
        surface: Colors.white,
        onSurface: ink,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        background: paperDark,
        surface: const Color(0xFF3A3733),
        onSurface: const Color(0xFFF3ECDC),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color onSurface,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      surface: surface,
      onSurface: onSurface,
    ).copyWith(background: background);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: handFontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
          fontFamily: handFontFamily,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 1,
        margin: const EdgeInsets.symmetric(
          horizontal: spaceM,
          vertical: spaceS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceL,
            vertical: spaceM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.all(spaceM),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide.none,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: StadiumBorder(),
      ),
    );
  }
}
