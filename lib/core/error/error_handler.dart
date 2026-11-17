import 'dart:ui';

import 'package:flutter/foundation.dart';

/// 统一异常处理（core/error）。
///
/// 一期仅本地记录，禁止任何外发（R1 / R7）。
abstract final class ErrorHandler {
  static void onFlutterError(FlutterErrorDetails details) {
    debugPrint('[纸间账] FlutterError: ${details.exceptionAsString()}');
  }

  static bool onPlatformError(Object error, StackTrace stackTrace) {
    debugPrint('[纸间账] PlatformError: $error');
    // 返回 false：不吞掉平台异常，保留默认上报到控制台的行为。
    return false;
  }
}

/// 业务异常基类：Repository / Usecase 抛出，UI 层统一转成用户可读提示。
class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => code == null ? message : '$code: $message';
}
