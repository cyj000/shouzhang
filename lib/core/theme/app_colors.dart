import 'package:flutter/material.dart';

/// 色彩 Design Token —— 全工程色彩的唯一事实源（视觉专项 v1.0 §2.1）。
///
/// ⚠️ 硬编码禁令：业务代码禁止出现 `Color(0x...)` / `Colors.xxx` 字面量，
/// 唯一允许写色值字面量的文件就是本文件。所有色值已按 WCAG 实测校准（§2.5），
/// 调色只需改这里，不动业务组件。
abstract final class AppColors {
  // —— 纸张 / 墨色（校准值）——
  static const Color paperBg = Color(0xFFFBF3E4);
  static const Color paperCard = Color(0xFFFFFCF5);
  static const Color inkPrimary = Color(0xFF6B4F3A);
  static const Color inkSecondary = Color(0xFF756552);

  // —— 强调色（校准值：白字/大字/图形对比度达标）——
  static const Color accentCoral = Color(0xFFC4663E);
  static const Color accentMint = Color(0xFF6B8A5F);
  static const Color accentCoralDeep = Color(0xFFA34F2B);

  // —— 装饰色（胶带粉/贴纸黄，不承载文字，不受对比度约束）——
  static const Color tapePink = Color(0xFFE8B4B8);
  static const Color stickerYellow = Color(0xFFE3B23C);
  static const Color stickerCoffee = Color(0xFFA98467);
  static const Color stickerCoral = Color(0xFFD98F73);
  static const Color stickerBlue = Color(0xFF8CA9BF);

  // —— 语义 / 功能色 ——
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB3261E);
  static const Color transparent = Color(0x00000000);
  static const Color shadow = Color(0x14000000);

  // —— 暗色主题（沿用一期，集中在此便于统一治理）——
  static const Color paperDark = Color(0xFF2B2926);
  static const Color surfaceDark = Color(0xFF3A3733);
  static const Color onSurfaceDark = Color(0xFFF3ECDC);

  // ————————————————————————————————————————————————
  // 兼容别名：供旧 `AppTheme` 门面引用，值全部来自上方 Token。
  // 目的是让现有 74+ 处 `AppTheme.xxx` 引用零改动即可编译，
  // 同时保证色值字面量只在本文件出现一次。
  // ————————————————————————————————————————————————
  static const Color paper = paperBg;
  static const Color ink = inkPrimary;
  static const Color inkSoft = inkSecondary;
  static const Color accent = accentCoral;
  static const Color accentDark = accentCoralDeep;
  static const Color income = accentMint;
  static const Color expense = accentCoral;
}
