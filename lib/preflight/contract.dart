/// contract v1.0 冻结常量（PKG-08 / FR-41）。
///
/// 一期仅冻结口径；同步协议、鉴权、错误码的「实现」均不做（REV-08）。
/// 完整契约见 docs/contract_v1.0.md。
abstract final class ContractV1 {
  static const String version = '1.0';
  static const String schemaVersion = 'entries.revision/v1';
  static const String providerAuthority = 'com.paperledger.app.provider';
  static const String readPermission =
      'com.paperledger.app.permission.READ_LEDGER';

  /// 二期错误码预留（一期不触发、不上报）。
  static const int errorUnauthorized = 401;
  static const int errorConflict = 409;
  static const int errorGone = 410;
}
