import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/review/review_controller.dart';
import 'features/settings/lock_gate.dart';
import 'features/sticker/tombstone_cleanup.dart';

/// 根组件：MaterialApp + 声明式路由 + 手绘风主题 + 锁屏门控。
class PaperLedgerApp extends ConsumerStatefulWidget {
  const PaperLedgerApp({super.key});

  @override
  ConsumerState<PaperLedgerApp> createState() => _PaperLedgerAppState();
}

class _PaperLedgerAppState extends ConsumerState<PaperLedgerApp> {
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_bootstrapped) return;
      _bootstrapped = true;
      // 首屏后再做后台/埋点初始化，不阻塞「打开即录」（FR-01）。
      TombstoneCleanup.initialize();
      _trackAppOpen();
    });
  }

  Future<void> _trackAppOpen() async {
    try {
      final repos = await ref.read(appRepositoriesProvider.future);
      await ref
          .read(reviewControllerProvider.notifier)
          .trackAppOpen(repos.oplog.deviceId);
    } catch (_) {
      // 埋点失败不影响主流程（R7：仅本地）。
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return LockGate(
      child: MaterialApp.router(
        title: '纸间账',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: router,
        builder: (context, child) {
          // 文字随系统字号缩放时设上限，避免手账排版被撑破。
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
