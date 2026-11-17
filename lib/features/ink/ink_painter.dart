import 'package:flutter/material.dart';

import 'ink_models.dart';

/// Skia CustomPainter：手绘笔迹。落笔 <50ms 为目标值（PKG-09 真机校准）。
class InkPainter extends CustomPainter {
  const InkPainter({
    required this.strokes,
    this.active,
  });

  final List<InkStroke> strokes;
  final InkStroke? active;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in <InkStroke>[
      ...strokes,
      if (active != null) active!,
    ]) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = Color(stroke.colorValue)
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (var i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant InkPainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.active != active;
}
