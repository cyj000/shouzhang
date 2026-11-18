import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';

/// 贴纸边框 + 落下微动效（§2.3 / §2.4，L1 专用）。
///
/// 贴纸落在卡片上时从上方轻轻落下并渐显；动效受全局开关控制，
/// 关闭时直接到位（零动画）。描边用手绘色而非系统默认。
class StickerFrame extends ConsumerStatefulWidget {
  const StickerFrame({required this.child, super.key, this.tint});

  final Widget child;
  final Color? tint;

  @override
  ConsumerState<StickerFrame> createState() => _StickerFrameState();
}

class _StickerFrameState extends ConsumerState<StickerFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
  );

  @override
  void initState() {
    super.initState();
    _play();
  }

  void _play() {
    if (ref.read(motionEnabledProvider)) {
      _controller.forward(from: 0);
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(motionEnabledProvider);
    final curve = CurvedAnimation(parent: _controller, curve: AppMotion.curveSoft);
    final slide = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(curve);
    final fade = Tween<double>(begin: 0, end: 1).animate(curve);

    final body = DecoratedBox(
      decoration: BoxDecoration(
        color: (widget.tint ?? AppColors.paperCard).withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppShape.radiusMd),
        border: Border.all(
          color: widget.tint ?? AppColors.accentCoral,
          width: AppShape.strokeHandDrawn,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppShape.spacingSm),
        child: widget.child,
      ),
    );

    if (!enabled) return body;
    return SlideTransition(
      position: slide,
      child: FadeTransition(opacity: fade, child: body),
    );
  }
}
