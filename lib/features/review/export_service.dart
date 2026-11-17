import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/models/records.dart';
import '../../domain/usecases/amount_parser.dart';

/// FR-24：CSV / 图片导出。保存到应用私有目录，不申请存储权限、不外发（R1/R6）。
class ExportService {
  const ExportService();

  Future<String> exportCsv(List<EntryRow> entries) async {
    final rows = <List<dynamic>>[
      <dynamic>['时间', '类型', '金额(元)', '备注', '支付方式'],
    ];
    for (final entry in entries) {
      rows.add(<dynamic>[
        DateTime.fromMillisecondsSinceEpoch(entry.occurredAt)
            .toLocal()
            .toIso8601String(),
        entry.type == 'expense' ? '支出' : '收入',
        formatYuan(entry.amountCents), // 分单位整数转字符串，无浮点误差
        entry.note ?? '',
        entry.paymentMethod ?? '',
      ]);
    }
    final file = await _targetFile('csv');
    await file.writeAsString(
      const ListToCsvConverter().convert(rows),
      encoding: utf8,
    );
    return file.path;
  }

  Future<String?> exportImage(GlobalKey boundaryKey) async {
    final context = boundaryKey.currentContext;
    if (context == null) return null;
    final object = context.findRenderObject();
    if (object is! RenderRepaintBoundary) return null;

    final image = await object.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final file = await _targetFile('png');
    final bytes = byteData.buffer.asUint8List();
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<File> _targetFile(String extension) async {
    final dir = await getApplicationDocumentsDirectory();
    final name =
        'paper_ledger_${DateTime.now().millisecondsSinceEpoch}.$extension';
    return File(p.join(dir.path, name));
  }
}

/// 供 UI 展示导出成功提示（不显示完整路径以外的敏感信息）。
String exportDisplayName(String path) => p.basename(path);
