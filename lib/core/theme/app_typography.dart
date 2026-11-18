import 'package:flutter/material.dart';

/// 字体 Design Token（视觉专项 v1.0 §2.2）。
///
/// 体积约束已解除：可商用中文手写字体完整字库直接打包，无需子集化。
/// 授权凭证登记见 `docs/visual_asset_licenses.md`，字体文件声明见 `pubspec.yaml`。
abstract final class AppTypography {
  /// 中文手写字体族（标题 / 金额 / 情感文案）。
  /// 具体选型可商用即可，换字体只改这里 + pubspec 声明，不动业务代码。
  static const String handwritingFamily = 'LXGWWenKai';

  /// 正文 / 长文本 / 数字列表：系统无衬线（fontFamily=null 跟随平台默认，
  /// Android 为 Roboto + 系统中文字体），保证可读性与数字清晰。
  static const String? bodyFamily = null;

  // —— 字号（可访问性下限 caption ≥ 11）——
  static const double sizeAmount = 36; // 金额加大，32~40sp
  static const double sizeTitle = 22; // 标题 20~24sp
  static const double sizeBody = 15; // 正文 14~16sp
  static const double sizeCaption = 11; // 辅助 ≥11sp
  static const double sizeKeycap = 20; // 自绘键盘键帽

  /// 金额数字样式：默认用 body 字体确保 1/7、0/O 清晰可辨（§2.2 注记）。
  /// 若设计评审确认手写体数字可辨，改为 handwritingFamily 即可。
  static const TextStyle amountStyle = TextStyle(
    fontFamily: bodyFamily,
    fontSize: sizeAmount,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle amountPrefixStyle = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 28,
  );
}
