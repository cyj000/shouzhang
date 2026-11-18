import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 极轻纸纹（低对比度），仅作背景质感（§2.3）。
///
/// ⚠️ 禁用于 L0 记账页金额区：叠加纹样会降低金额清晰度，破速度/可读性红线。
/// 用 CustomPainter 画低透明度细点，无图片资源，零联网、零体积负担。
class PaperTexture extends StatelessWidget {
  const PaperTexture({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: const _PaperGrainPainter()),
          ),
        ),
        child,
      ],
    );
  }
}

class _PaperGrainPainter extends CustomPainter {
  const _PaperGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.inkPrimary.withOpacity(0.035)
      ..style = PaintingStyle.fill;
    // 稀疏细点模拟纸纤维；间距 9px，直径 <1px，肉眼近乎无感。
    const double gap = 9;
    for (double x = gap / 2; x < size.width; x += gap) {
      for (double y = gap / 2; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 0.45, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
