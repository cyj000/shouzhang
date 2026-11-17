import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local/database.dart';
import '../../data/repository/app_repositories.dart';
import '../../domain/usecases/classifier.dart';
import '../../security/keystore.dart';

/// 依赖注入容器（Riverpod，PKG-01 锁定选型）。
///
/// 各包在此追加 provider：PKG-02 数据库/仓库、PKG-03 用例、PKG-07 认证等。
/// 约定：UI 只 watch/ref 这里的 provider，不直接 new 数据源。

/// 仓库容器：DQ-01 密钥链路 + SQLCipher 打开 + app-set device id。
final appRepositoriesProvider = FutureProvider<AppRepositories>((ref) async {
  final passphrase = await KeystoreService.loadOrCreateDbPassphrase();
  final deviceId = await KeystoreService.loadOrCreateDeviceId();
  final db = AppDatabase.openEncrypted(passphrase);
  ref.onDispose(() {
    db.close();
  });
  return AppRepositories(db, deviceId: deviceId);
});

/// 设备 ID（埋点 / oplog 幂等键）。
final deviceIdProvider = FutureProvider<String>((ref) async {
  final repos = await ref.watch(appRepositoriesProvider.future);
  return repos.oplog.deviceId;
});

/// 轻量偏好（上次支付方式、键盘模式等非敏感设置）。
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  ref.onDispose(() {});
  return prefs;
});

/// 本地词库分类器（FR-07/08）。纠错学习后 invalidate 此 provider 生效。
final classifierProvider = FutureProvider<Classifier>((ref) async {
  final library = await KeywordLibrary.load();
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final store = UserKeywordStore(prefs);
  return Classifier(
    library,
    userWords: store.loadWords(),
    demoted: store.loadDemoted(),
  );
});

/// 键盘模式：false=系统键盘（默认，DQ-02），true=自绘键盘（SP-03 对比用）。
final useCustomKeypadProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool('use_custom_keypad') ?? false;
});
