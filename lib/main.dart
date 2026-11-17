import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/error/error_handler.dart';

/// 应用入口。
///
/// 一期（Android only）：冷启动直落记账页（FR-01 / R5 默认免密）。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 统一异常兜底：防止 UI 层异常导致数据状态不一致。
  FlutterError.onError = ErrorHandler.onFlutterError;
  PlatformDispatcher.instance.onError = ErrorHandler.onPlatformError;

  // 固定竖屏，贴合手账单手极速记账场景。
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(const ProviderScope(child: PaperLedgerApp()));
}
