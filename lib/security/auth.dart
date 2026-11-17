import 'package:local_auth/local_auth.dart';

import 'keystore.dart';

/// FR-33 / DQ-04：可选锁屏认证。
///
/// 默认免密（R5），用户主动开启后才认证；认证时间戳加密本地持久化，
/// 5 分钟宽限期；重启是否清零 ⚠️待确认 —— 默认重启需重新认证。
abstract final class AuthPolicy {
  static const Duration gracePeriod = Duration(minutes: 5);
  static const String _enabledKey = 'lock_screen_enabled';
  static const String _sessionAuthenticatedKey = 'session_authenticated';
}

class AuthService {
  AuthService(this._localAuth);

  final LocalAuthentication _localAuth;

  Future<bool> isEnabled() async {
    final value = await KeystoreService.readEncrypted(AuthPolicy._enabledKey);
    return value == '1';
  }

  Future<void> setEnabled(bool enabled) async {
    await KeystoreService.writeEncrypted(
      AuthPolicy._enabledKey,
      enabled ? '1' : '0',
    );
    if (!enabled) await clearSession();
  }

  /// 本次进程内是否已认证（重启即清零，默认行为）。
  bool _sessionAuthenticated = false;

  Future<bool> canAuthenticate() async {
    try {
      final result = await _localAuth.canCheckBiometrics;
      final devices = await _localAuth.getAvailableBiometrics();
      return result || devices.isNotEmpty;
    } catch (_) {
      // 无生物识别硬件时允许设备密码兜底，交由 authenticate 处理。
      return true;
    }
  }

  /// 是否需要认证：锁屏关闭 → 否；5 分钟宽限期内 → 否；本会话已认证 → 否。
  Future<bool> needsAuth() async {
    if (!await isEnabled()) return false;
    if (_sessionAuthenticated) return false;
    final last = await KeystoreService.readAuthTimestamp();
    if (last == null) return true;
    final elapsed = DateTime.now().millisecondsSinceEpoch - last;
    return elapsed > AuthPolicy.gracePeriod.inMilliseconds;
  }

  Future<bool> authenticate() async {
    final ok = await _localAuth.authenticate(
      localizedReason: '验证身份以查看账目',
      options: const AuthenticationOptions(
        biometricOnly: false, // 支持生物识别或设备密码
        stickyAuth: true,
      ),
    );
    if (ok) {
      _sessionAuthenticated = true;
      await KeystoreService.writeAuthTimestamp(
        DateTime.now().millisecondsSinceEpoch,
      );
    }
    return ok;
  }

  Future<void> clearSession() async {
    _sessionAuthenticated = false;
    await KeystoreService.clearAuthTimestamp();
  }
}
