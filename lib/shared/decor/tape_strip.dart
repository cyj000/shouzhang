import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shape.dart';

/// 胶带条装饰（§2.3，L1/L2 专用，禁用于 L0 主路径）。
///
/// 一段微旋转的半透明色带，盖在卡片/便签上做"贴上去"的手账感。
/// 仅装饰、不承载文字，故可用装饰色而免对比度约束。
class TapeStrip extends StatelessWidget {
  const TapeStrip({
    super.key,
    this.color = AppColors.tapePink,
    this.width = 72,
    this.height = 22,
    this.tilt = AppShape.tapeTilt,
  });

  final Color color;
  final double width;
  final double height;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color.withOpacity(0.75),
          borderRadius: BorderRadius.circular(AppShape.radiusSm / 2),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// 左右交替倾斜，避免多段胶带方向完全一致显得呆板。
TapeStrip alternatingTape(int index, {Color color = AppColors.tapePink}) =>
    TapeStrip(
      color: color,
      tilt: index.isEven ? -AppShape.tapeTilt : AppShape.tapeTilt,
    );

/// 供装饰内部使用的确定性伪随机角（无全局随机状态，可复现）。
double deterministicTilt(int seed) =>
    (math.Random(seed).nextDouble() - 0.5) * 2 * AppShape.tapeTilt;
