import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 动效 Design Token + 全局开关（视觉专项 v1.0 §2.4）。
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Curve curveSoft = Curves.easeOutCubic;
}

/// 全局动效开关（默认开）。设置页开关控制；关闭时所有 L1/L2 装饰动效禁用。
/// L0 记账主路径本就禁止新增动画，不受此开关影响。
final motionEnabledProvider = StateProvider<bool>((ref) => true);

/// 按开关返回实际时长：关闭时返回 zero，动画即"瞬移"。
Duration motionDuration(WidgetRef ref, Duration duration) =>
    ref.watch(motionEnabledProvider) ? duration : Duration.zero;
