import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/local/database.dart';
import '../../data/repository/app_repositories.dart';
import '../../security/keystore.dart';

/// DQ-05：tombstone 90 天后清理 —— 前台检查 + WorkManager 空闲调度。
/// 清理前须提示用户并允许延长（提示 UI 见 PKG-07 设置页）。
@pragma('vm:entry-point')
void tombstoneCleanupDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().executeTask((task, inputData) async {
    if (task != TombstoneCleanup.taskName) return true;
    try {
      final passphrase = await KeystoreService.loadOrCreateDbPassphrase();
      final deviceId = await KeystoreService.loadOrCreateDeviceId();
      final db = AppDatabase.openEncrypted(passphrase);
      final repos = AppRepositories(db, deviceId: deviceId);
      await repos.entries.purgeTombstones();
      await repos.stickers.purgeRemoved();
      await db.close();
      return true;
    } catch (_) {
      return false;
    }
  });
}

class TombstoneCleanup {
  static const String taskName = 'paper_ledger_tombstone_cleanup';

  static Future<void> initialize() async {
    await Workmanager().initialize(
      tombstoneCleanupDispatcher,
      isInDebugMode: false,
    );
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: const Duration(days: 1),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresDeviceIdle: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  /// 前台确认后执行；返回清理条数。
  static Future<int> runAfterConsent(AppRepositories repos) async {
    final entries = await repos.entries.purgeTombstones();
    final stickers = await repos.stickers.purgeRemoved();
    return entries + stickers;
  }
}
