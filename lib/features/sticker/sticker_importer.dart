import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../data/models/records.dart';
import '../../data/repository/app_repositories.dart';
import '../../domain/entities/constants.dart';
import '../../security/cipher.dart';
import '../../telemetry/events.dart';
import '../../telemetry/local_logger.dart';
import 'license_guard.dart';

/// FR-14~16：素材导入、许可校验、checksum 去重、来源留痕。
class StickerImporter {
  const StickerImporter(this._repos, this._telemetry);

  final AppRepositories _repos;
  final TelemetrySink _telemetry;

  Future<StickerImportOutcome> import({
    required String sourceUrl,
    required String license,
    required String? licenseCheckShot,
    required String? author,
    required List<int> bytes,
    required List<String> attributes,
  }) async {
    final check = LicenseGuard.check(
      license: license,
      sourceUrl: sourceUrl,
      licenseCheckShot: licenseCheckShot,
    );
    if (!check.accepted) {
      await _telemetry.track(
        TelemetryEventNames.stickerImport,
        TelemetryEvents.stickerImport(
          sourceUrl: sourceUrl,
          license: license,
          attributeCount: attributes.length,
          result: 'rejected_${check.reasonCode}',
        ),
      );
      return StickerImportOutcome.rejected(
        LicenseGuard.reasonText(check.reasonCode),
      );
    }

    final checksum = Cipher.checksumOf(bytes);
    final existing = await _repos.stickers.findByChecksum(checksum);
    if (existing != null) {
      await _telemetry.track(
        TelemetryEventNames.stickerImport,
        TelemetryEvents.stickerImport(
          sourceUrl: sourceUrl,
          license: check.normalizedLicense!,
          attributeCount: attributes.length,
          result: 'duplicate',
        ),
      );
      return StickerImportOutcome.duplicate(existing.id);
    }

    final id = const Uuid().v4();
    final assetPath = 'local://stickers/$id.bin';
    await _repos.stickers.saveSticker(
      StickerRow(
        id: id,
        assetPath: assetPath,
        attributesJson: jsonEncode(attributes),
        source: '开源预设',
        checksum: checksum,
      ),
    );
    await _repos.stickers.saveSource(
      StickerSourceRow(
        stickerId: id,
        sourceUrl: sourceUrl,
        license: check.normalizedLicense!,
        obtainedAt: DateTime.now().millisecondsSinceEpoch,
        author: author,
        licenseCheckShot: licenseCheckShot!,
      ),
    );

    await _telemetry.track(
      TelemetryEventNames.stickerImport,
      TelemetryEvents.stickerImport(
        sourceUrl: sourceUrl,
        license: check.normalizedLicense!,
        attributeCount: attributes.length,
        result: 'accepted',
      ),
    );
    return StickerImportOutcome.accepted(id);
  }
}

class StickerImportOutcome {
  const StickerImportOutcome._(this.accepted, this.stickerId, this.message);

  factory StickerImportOutcome.accepted(String id) =>
      StickerImportOutcome._(true, id, null);
  factory StickerImportOutcome.duplicate(String id) =>
      StickerImportOutcome._(false, id, '素材已存在，已复用');
  factory StickerImportOutcome.rejected(String message) =>
      StickerImportOutcome._(false, null, message);

  final bool accepted;
  final String? stickerId;
  final String? message;
}
