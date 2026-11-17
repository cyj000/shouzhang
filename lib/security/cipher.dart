import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// 加解密封装（任务书 §2.1 security/cipher.dart）。
///
/// 数据库正文加密由 SQLCipher 承担；这里负责 passphrase 生成与资源 checksum。
/// 禁止把密钥/明文写进普通文件（R1 / DQ-01）。
abstract final class Cipher {
  static String sha256Hex(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  static String checksumOf(List<int> bytes) =>
      sha256.convert(bytes).toString();

  /// 生成 256bit 随机 passphrase（base64url，无引号，可安全嵌入 PRAGMA key）。
  static String generatePassphrase({int byteLength = 32}) {
    final random = Random.secure();
    final bytes = List<int>.generate(
      byteLength,
      (_) => random.nextInt(256),
      growable: false,
    );
    return base64Url.encode(bytes);
  }
}
