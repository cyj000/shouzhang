import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_ledger/core/theme/app_colors.dart';

/// 视觉专项 VPKG-05：Design Token 对比度契约测试（§5.4）。
///
/// 本环境无 Flutter SDK，测试代码编写归档，执行标注「待有环境」。
/// 计算标准：WCAG 2.1 相对亮度与对比度公式。

double _channelLinear(num c8) {
  final c = c8 / 255;
  return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055);
}

double _luminance(Color color) {
  final r = _channelLinear(color.red);
  final g = _channelLinear(color.green);
  final b = _channelLinear(color.blue);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double contrastRatio(Color a, Color b) {
  final l1 = _luminance(a);
  final l2 = _luminance(b);
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('Design Token 对比度契约（WCAG 2.1）', () {
    test('inkPrimary on paperBg 正文 >= 4.5', () {
      expect(
        contrastRatio(AppColors.inkPrimary, AppColors.paperBg) >= 4.5,
        isTrue,
        reason: '正文/金额主色对必须达标',
      );
    });

    test('inkPrimary on paperCard 卡片正文 >= 4.5', () {
      expect(
        contrastRatio(AppColors.inkPrimary, AppColors.paperCard) >= 4.5,
        isTrue,
      );
    });

    test('inkSecondary on paperBg 次要正文 >= 4.5', () {
      expect(
        contrastRatio(AppColors.inkSecondary, AppColors.paperBg) >= 4.5,
        isTrue,
      );
    });

    test('白字 on coralDeep 主按钮 >= 4.5', () {
      expect(
        contrastRatio(AppColors.onPrimary, AppColors.accentCoralDeep) >= 4.5,
        isTrue,
        reason: '主按钮白字校准后须达标（§2.5）',
      );
    });

    test('coral on paperBg 大字/图形 >= 3.0', () {
      expect(
        contrastRatio(AppColors.accentCoral, AppColors.paperBg) >= 3.0,
        isTrue,
      );
    });

    test('mint on paperBg 大字/图形 >= 3.0', () {
      expect(
        contrastRatio(AppColors.accentMint, AppColors.paperBg) >= 3.0,
        isTrue,
      );
    });
  });
}
