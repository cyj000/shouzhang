import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import 'cipher.dart';

/// Android Keystore(TEE) 密钥链路 —— DQ-01 默认方案。
///
/// 链路：Keystore 生成/持有 AES 主密钥 → 加密随机 passphrase → 密文落私有目录
/// → 运行时解出 passphrase → 交给 SQLCipher 打开库。
/// flutter_secure_storage 的 `encryptedSharedPreferences` 后端即 Keystore 包裹的
/// AES-GCM 主密钥 + 加密落盘，等价满足上述链路；密文不明文可见（R1 / R5 / DQ-01）。
abstract final class KeystoreService {
  static const String _passphraseKey = 'db_passphrase_cipher';
  static const String _deviceIdKey = 'app_set_device_id';
  static const String _authTsKey = 'auth_ts_encrypted';

  static final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: const AndroidOptions(encryptedSharedPreferences: true),
  );

  /// 首次生成 passphrase 并加密落盘；之后复用。密钥丢失（卸载/清除数据）时重新生成。
  static Future<String> loadOrCreateDbPassphrase() async {
    final stored = await _storage.read(key: _passphraseKey);
    if (stored != null && stored.isNotEmpty) return stored;
    final passphrase = Cipher.generatePassphrase();
    await _storage.write(key: _passphraseKey, value: passphrase);
    return passphrase;
  }

  /// 应用专属 ID（app-set ID），不追求跨重装稳定（任务书 §1.4）。
  static Future<String> loadOrCreateDeviceId() async {
    final stored = await _storage.read(key: _deviceIdKey);
    if (stored != null && stored.isNotEmpty) return stored;
    final id = const Uuid().v4();
    await _storage.write(key: _deviceIdKey, value: id);
    return id;
  }

  /// 供 PKG-07 认证时间戳持久化（加密本地存储）。
  static Future<void> writeAuthTimestamp(int epochMs) =>
      _storage.write(key: _authTsKey, value: epochMs.toString());

  static Future<int?> readAuthTimestamp() async {
    final raw = await _storage.read(key: _authTsKey);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  static Future<void> clearAuthTimestamp() =>
      _storage.delete(key: _authTsKey);

  /// 通用加密 KV 读写：供 PKG-07 开关等非时间戳类小数据复用。
  static Future<String?> readEncrypted(String key) => _storage.read(key: key);

  static Future<void> writeEncrypted(String key, String value) =>
      _storage.write(key: key, value: value);
}
