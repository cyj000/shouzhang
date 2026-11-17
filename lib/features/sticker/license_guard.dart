/// 开源许可白名单校验（R3 / FR-14）。
///
/// 仅允许 CC0 / CC BY；CC BY-SA / CC BY-NC / 来源不明 / 许可原文缺失一律拒绝。
/// 「逐张核对许可原文留截图」需人工核对后填入 licenseCheckShot 路径（见 docs/license_audit.md）。
abstract final class LicenseGuard {
  static const Set<String> allowed = <String>{'CC0', 'CC BY'};

  static const int reasonNonFree = 1;
  static const int reasonMissingSource = 2;
  static const int reasonMissingLicense = 3;
  static const int reasonMissingShot = 4;

  static LicenseCheck check({
    required String license,
    required String sourceUrl,
    required String? licenseCheckShot,
  }) {
    if (sourceUrl.trim().isEmpty) {
      return const LicenseCheck.rejected(reasonMissingSource);
    }
    final normalized = license.trim().toUpperCase();
    if (normalized.isEmpty) {
      return const LicenseCheck.rejected(reasonMissingLicense);
    }
    if (!allowed.contains(normalized)) {
      return const LicenseCheck.rejected(reasonNonFree);
    }
    if (licenseCheckShot == null || licenseCheckShot.trim().isEmpty) {
      return const LicenseCheck.rejected(reasonMissingShot);
    }
    return LicenseCheck.accepted(normalized);
  }

  static String reasonText(int reason) {
    switch (reason) {
      case reasonNonFree:
        return '仅接受 CC0 / CC BY，拒绝 SA / NC / 来源不明';
      case reasonMissingSource:
        return '缺少来源 URL';
      case reasonMissingLicense:
        return '缺少许可原文';
      case reasonMissingShot:
        return '缺少许可核对截图';
      default:
        return '许可校验未通过';
    }
  }
}

class LicenseCheck {
  const LicenseCheck.accepted(this.normalizedLicense)
      : accepted = true,
        reasonCode = 0;
  const LicenseCheck.rejected(this.reasonCode)
      : accepted = false,
        normalizedLicense = null;

  final bool accepted;
  final String? normalizedLicense;
  final int reasonCode;
}
