import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_shape.dart';
import 'app_typography.dart';

/// 手绘风 Design Token 门面（PKG-01）。
///
/// 实际单一事实源已拆分到：
/// - [AppColors]  色彩
/// - [AppTypography] 字体
/// - [AppShape]   圆角 / 间距 / 描边
/// - `app_motion.dart` 动效
///
/// 本类保留旧常量名做向后兼容（现有业务引用零改动即可编译），
/// 所有值均转发到新 Token，不再在此写任何色值 / 魔法数字面量。
abstract final class AppTheme {
  // —— 色彩（转发 Token）——
  static const Color paper = AppColors.paperBg;
  static const Color paperDark = AppColors.paperDark;
  static const Color ink = AppColors.inkPrimary;
  static const Color inkSoft = AppColors.inkSecondary;
  static const Color accent = AppColors.accentCoral;
  static const Color accentDark = AppColors.accentCoralDeep;
  static const Color income = AppColors.accentMint;
  static const Color expense = AppColors.accentCoral;

  static const Color paperBg = AppColors.paperBg;
  static const Color paperCard = AppColors.paperCard;
  static const Color inkPrimary = AppColors.inkPrimary;
  static const Color inkSecondary = AppColors.inkSecondary;
  static const Color accentCoral = AppColors.accentCoral;
  static const Color accentMint = AppColors.accentMint;
  static const Color accentCoralDeep = AppColors.accentCoralDeep;
  static const Color tapePink = AppColors.tapePink;
  static const Color stickerYellow = AppColors.stickerYellow;
  static const Color stickerCoffee = AppColors.stickerCoffee;
  static const Color stickerCoral = AppColors.stickerCoral;
  static const Color stickerBlue = AppColors.stickerBlue;

  // —— 间距（转发 Token）——
  static const double spaceXS = AppShape.spacingXs;
  static const double spaceS = AppShape.spacingSm;
  static const double spaceM = AppShape.spacingLg;
  static const double spaceL = AppShape.spacingXl;
  static const double spaceXL = AppShape.spacingXxl;

  // —— 圆角（转发 Token）——
  static const double radiusS = AppShape.radiusSm;
  static const double radiusM = AppShape.radiusMd;
  static const double radiusL = AppShape.radiusLg;

  /// 手写字体族（兼容旧引用；新代码请用 AppTypography.handwritingFamily）。
  static const String handFontFamily = AppTypography.handwritingFamily;

  static ThemeData light() => _build(
        brightness: Brightness.light,
        background: AppColors.paperBg,
        surface: AppColors.paperCard,
        onSurface: AppColors.inkPrimary,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        background: AppColors.paperDark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.onSurfaceDark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color onSurface,
  }) {
    final isLight = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accentCoral,
      brightness: brightness,
      surface: surface,
      onSurface: onSurface,
    ).copyWith(
      background: background,
      primary: isLight ? AppColors.accentCoralDeep : AppColors.accentCoral,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.accentMint,
      error: AppColors.error,
      surfaceContainerHighest: isLight
          ? AppColors.paperBg
          : AppColors.surfaceDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: AppTypography.bodyFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.handwritingFamily,
          fontSize: AppTypography.sizeTitle,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 1,
        margin: const EdgeInsets.symmetric(
          horizontal: AppShape.spacingLg,
          vertical: AppShape.spacingSm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.radiusMd),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppShape.spacingXl,
            vertical: AppShape.spacingLg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShape.radiusMd),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShape.radiusMd),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.all(AppShape.spacingLg),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppShape.radiusMd),
          borderSide: BorderSide.none,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: AppColors.onPrimary,
        shape: const StadiumBorder(),
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          fontFamily: AppTypography.handwritingFamily,
          fontSize: AppTypography.sizeTitle,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        titleLarge: TextStyle(
          fontFamily: AppTypography.handwritingFamily,
          fontSize: AppTypography.sizeTitle,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        titleMedium: TextStyle(
          fontFamily: AppTypography.handwritingFamily,
          fontSize: AppTypography.sizeBody + 2,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppTypography.bodyFamily,
          fontSize: AppTypography.sizeBody,
          color: onSurface,
        ),
        bodySmall: TextStyle(
          fontFamily: AppTypography.bodyFamily,
          fontSize: AppTypography.sizeCaption,
          color: isLight ? AppColors.inkSecondary : AppColors.onSurfaceDark,
        ),
      ),
    );
  }
}
