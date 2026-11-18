import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_typography.dart';

/// 空状态生活插画 + 情感化文案（§2.3 / L2 情感层）。
///
/// 纯自绘矢量（CC0，无外部素材、无联网），一个暖色账本 + 纸胶带意象。
/// 文案温和可恢复，避免冷冰冰的"暂无数据"。
class EmptyStateArt extends StatelessWidget {
  const EmptyStateArt({
    super.key,
    this.title = '这一页还空着',
    this.hint = '记下第一笔，故事就开始了',
    this.icon = Icons.receipt_long_outlined,
  });

  final String title;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title，$hint',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.paperCard,
                  borderRadius: BorderRadius.circular(AppShape.radiusLg + 4),
                  border: Border.all(
                    color: AppColors.inkSecondary.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 44,
                  color: AppColors.accentCoral.withOpacity(0.7),
                ),
              ),
              Positioned(
                top: -4,
                child: Container(
                  width: 40,
                  height: 14,
                  color: AppColors.tapePink.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTypography.handwritingFamily,
              fontSize: AppTypography.sizeTitle,
              color: AppColors.inkPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.bodyFamily,
                fontSize: AppTypography.sizeBody,
                color: AppColors.inkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
