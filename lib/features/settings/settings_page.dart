import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/auth_providers.dart';
import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/constants.dart';
import '../sticker/tombstone_cleanup.dart';

/// 设置页（FR-32~33）：权限说明、可选锁屏、键盘模式、tombstone 清理提示。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _lockEnabled = false;
  bool _loaded = false;
  bool _customKeypad = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = ref.read(authServiceProvider);
    final enabled = await auth.isEnabled();
    final prefs = await ref.read(sharedPreferencesProvider.future);
    if (!mounted) return;
    setState(() {
      _lockEnabled = enabled;
      _customKeypad = prefs.getBool('use_custom_keypad') ?? false;
      _loaded = true;
    });
  }

  Future<void> _toggleLock(bool value) async {
    final auth = ref.read(authServiceProvider);
    if (value && !await auth.canAuthenticate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设备未设置生物识别或密码，无法开启锁屏')),
        );
      }
      return;
    }
    await auth.setEnabled(value);
    setState(() => _lockEnabled = value);
    ref.invalidate(needsAuthProvider);
  }

  Future<void> _toggleKeypad(bool value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool('use_custom_keypad', value);
    setState(() => _customKeypad = value);
  }

  Future<void> _cleanup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理已删除记录'),
        content: Text(
          '将永久删除超过 ${RetentionRules.tombstoneDays} 天的账目与贴纸记录，'
          '此操作不可撤销。如需延长保留期请取消。',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('延长保留'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('立即清理'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final repos = await ref.read(appRepositoriesProvider.future);
    final count = await TombstoneCleanup.runAfterConsent(repos);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已清理 $count 条过期记录')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceL),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM),
            child: Text(
              '设置与隐私',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('锁屏保护'),
            subtitle: const Text('默认关闭；开启后 5 分钟宽限期，重启需重新认证'),
            value: _lockEnabled,
            onChanged: _toggleLock,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.keyboard_outlined),
            title: const Text('自绘数字键盘'),
            subtitle: const Text('默认系统键盘；自绘键盘用于真机输入延迟对比'),
            value: _customKeypad,
            onChanged: _toggleKeypad,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('清理已删除记录'),
            subtitle: Text(
              '保留 ${RetentionRules.tombstoneDays} 天后可清理，清理前提示',
            ),
            onTap: _cleanup,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spaceM,
              vertical: AppTheme.spaceS,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('权限与隐私说明', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: AppTheme.spaceS),
                Text('· 账目与埋点仅存储在本地，数据不出设备'),
                Text('· 不申请定位、录音权限，无语音与自动地点采集'),
                Text('· 相册/相机仅在导入贴纸时按需申请，拒绝后不反复打扰'),
                Text('· 数据库采用 SQLCipher AES-256 加密，密钥由系统 Keystore 保护'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
