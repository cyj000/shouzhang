import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../security/auth.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(LocalAuthentication());
});

/// 启动时是否需要认证（R5：默认免密直入；开启锁屏后冷启动需认证）。
final needsAuthProvider = FutureProvider<bool>((ref) async {
  return ref.watch(authServiceProvider).needsAuth();
});
