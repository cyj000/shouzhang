import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 本地崩溃日志（PKG-09）：可选，且仅写本地文件，绝不外发（R1/R7）。
///
/// 真机联调时可查看；上架版本默认关闭网络上报，仅留本地线索。
class CrashReporter {
  const CrashReporter({this.enabled = true});

  final bool enabled;
  static const String _fileName = 'crash_local.log';

  Future<void> init() async {
    if (!enabled) return;
    FlutterError.onError = (details) {
      record(
        'FlutterError: ${details.exceptionAsString()}',
        stack: details.stack,
      );
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      record('PlatformError: $error', stack: stack);
      return false;
    };
  }

  Future<void> record(String message, {StackTrace? stack}) async {
    if (!enabled) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, _fileName));
      final buffer = StringBuffer()
        ..writeln('[${DateTime.now().toUtc().toIso8601String()}] $message')
        ..writeln(stack?.toString() ?? '')
        ..writeln('---');
      await file.writeAsString(buffer.toString(), mode: FileMode.append);
    } catch (_) {
      // 崩溃日志写入失败不影响主流程。
      debugPrint('[纸间账] crash log write failed');
    }
  }
}
