import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/auth_providers.dart';

/// 锁屏门控（FR-33）：默认免密直通；开启后冷启动/超时需认证。
class LockGate extends ConsumerWidget {
  const LockGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needsAuth = ref.watch(needsAuthProvider);
    return needsAuth.when(
      data: (required) {
        if (!required) return child;
        return const _LockScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      // 认证服务异常时回落，避免卡死（默认免密 R5）。
      error: (error, stack) => child,
    );
  }
}

class _LockScreen extends ConsumerStatefulWidget {
  const _LockScreen();

  @override
  ConsumerState<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<_LockScreen> {
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.lock_outline, size: 64),
            const SizedBox(height: 24),
            const Text('纸间账已上锁'),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            FilledButton(
              onPressed: _busy ? null : _unlock,
              child: const Text('解锁'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unlock() async {
    setState(() => _busy = true);
    final ok = await ref.read(authServiceProvider).authenticate();
    if (!mounted) return;
    if (ok) {
      ref.invalidate(needsAuthProvider);
    } else {
      setState(() {
        _busy = false;
        _error = '认证未通过，请重试';
      });
    }
  }
}
