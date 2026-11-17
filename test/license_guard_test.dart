import 'package:flutter_test/flutter_test.dart';
import 'package:paper_ledger/features/sticker/license_guard.dart';

void main() {
  const url = 'https://example.com/sticker';
  const shot = 'screenshots/license_1.png';

  test('CC0 / CC BY 通过', () {
    expect(
      LicenseGuard.check(
        license: 'CC0',
        sourceUrl: url,
        licenseCheckShot: shot,
      ).accepted,
      isTrue,
    );
    expect(
      LicenseGuard.check(
        license: 'CC BY',
        sourceUrl: url,
        licenseCheckShot: shot,
      ).accepted,
      isTrue,
    );
  });

  test('CC BY-SA / CC BY-NC / 来源不明被拒绝', () {
    expect(
      LicenseGuard.check(
        license: 'CC BY-SA',
        sourceUrl: url,
        licenseCheckShot: shot,
      ).reasonCode,
      LicenseGuard.reasonNonFree,
    );
    expect(
      LicenseGuard.check(
        license: 'CC BY-NC',
        sourceUrl: url,
        licenseCheckShot: shot,
      ).reasonCode,
      LicenseGuard.reasonNonFree,
    );
    expect(
      LicenseGuard.check(
        license: '来源不明',
        sourceUrl: url,
        licenseCheckShot: shot,
      ).reasonCode,
      LicenseGuard.reasonNonFree,
    );
  });

  test('缺少来源 / 许可 / 截图被拒绝', () {
    expect(
      LicenseGuard.check(
        license: 'CC0',
        sourceUrl: '',
        licenseCheckShot: shot,
      ).reasonCode,
      LicenseGuard.reasonMissingSource,
    );
    expect(
      LicenseGuard.check(
        license: '',
        sourceUrl: url,
        licenseCheckShot: shot,
      ).reasonCode,
      LicenseGuard.reasonMissingLicense,
    );
    expect(
      LicenseGuard.check(
        license: 'CC0',
        sourceUrl: url,
        licenseCheckShot: null,
      ).reasonCode,
      LicenseGuard.reasonMissingShot,
    );
  });
}
