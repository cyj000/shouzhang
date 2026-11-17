import 'dart:convert';

import 'package:flutter/material.dart';

/// 笔刷参数与点位（非金额，允许 double）。
@immutable
class InkStroke {
  const InkStroke({
    required this.points,
    required this.colorValue,
    required this.width,
  });

  final List<Offset> points;
  final int colorValue;
  final double width;

  Map<String, Object?> toJson() => <String, Object?>{
        'color': colorValue,
        'width': width,
        'points': points
            .map((p) => <double>[p.dx, p.dy])
            .toList(growable: false),
      };

  factory InkStroke.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>;
    return InkStroke(
      colorValue: (json['color'] as num?)?.toInt() ?? 0xFF3B332B,
      width: (json['width'] as num?)?.toDouble() ?? 3.0,
      points: rawPoints
          .map(
            (p) => Offset(
              (p as List<dynamic>)[0] as double,
              p[1] as double,
            ),
          )
          .toList(growable: false),
    );
  }

  InkStroke copyWithPoints(List<Offset> newPoints) => InkStroke(
        points: newPoints,
        colorValue: colorValue,
        width: width,
      );
}

/// 增量指令数组：每次抬笔仅追加一条 stroke，非整图覆盖（FR-12）。
class InkDocument {
  const InkDocument(this.strokes);

  factory InkDocument.empty() => const InkDocument(<InkStroke>[]);

  factory InkDocument.decode(String raw) {
    if (raw.isEmpty) return InkDocument.empty();
    final decoded = jsonDecode(raw) as List<dynamic>;
    return InkDocument(
      decoded
          .map((e) => InkStroke.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final List<InkStroke> strokes;

  InkDocument append(InkStroke stroke) =>
      InkDocument(<InkStroke>[...strokes, stroke]);

  String encode() => jsonEncode(strokes.map((s) => s.toJson()).toList());
}
