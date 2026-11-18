import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// L0 记账页专用样式拆分（VPKG-02）。
///
/// 只承载「皮肤」：所有值来自 Design Token，业务 [entry_page] 不写硬编码。
/// 本文件不含任何交互 / 焦点 / 保存逻辑，也不含动画（L0 禁区）。
abstract final class EntryStyles {
  static const TextStyle amountInput = AppTypography.amountStyle;
  static const TextStyle amountPrefix = AppTypography.amountPrefixStyle;

  static const TextStyle saveButtonLabel = TextStyle(
    fontSize: AppTypography.sizeBody + 3,
    fontWeight: FontWeight.w600,
  );

  static TextStyle preview({required bool hasValue}) => TextStyle(
        fontFamily: AppTypography.bodyFamily,
        fontSize: AppTypography.sizeBody + 1,
        color: hasValue ? AppColors.accentCoral : AppColors.inkSecondary,
      );

  static TextStyle typeChipLabel(bool selected) => TextStyle(
        color: selected ? AppColors.onPrimary : AppColors.inkSecondary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      );
}
