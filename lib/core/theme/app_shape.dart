import 'package:flutter/material.dart';

/// 圆角 / 间距 / 描边 Design Token（视觉专项 v1.0 §2.3）。
abstract final class AppShape {
  // —— 圆角 ——
  static const double radiusSm = 8;
  static const double radiusMd = 16;
  static const double radiusLg = 24;

  // —— 间距（4pt 栅格）——
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 24;
  static const double spacingXxl = 32;

  // —— 手绘描边（L1/L2 贴纸 / 卡片）——
  static const double strokeHandDrawn = 1.75;

  // —— 胶带旋转角（±4°）——
  static const double tapeTilt = 0.07;

  // ————————————————————————————————————————————————
  // 兼容别名：对齐旧 AppTheme 间距/圆角名，保证现有引用零改动。
  // ————————————————————————————————————————————————
  static const double spaceXS = spacingXs;
  static const double spaceS = spacingSm;
  static const double spaceM = spacingLg;
  static const double spaceL = spacingXl;
  static const double spaceXL = spacingXxl;
  static const double radiusS = radiusSm;
  static const double radiusM = radiusMd;
  static const double radiusL = radiusLg;
}
