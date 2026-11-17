import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di/injection.dart';
import '../../data/models/records.dart';
import '../../data/repository/app_repositories.dart';
import '../../domain/entities/constants.dart';
import '../../telemetry/events.dart';
import '../../telemetry/local_logger.dart';
import 'sticker_catalog.dart';

final stickerApplicationProvider = FutureProvider<StickerApplication>((ref) async {
  final repos = await ref.read(appRepositoriesProvider.future);
  return StickerApplication(repos, ref.read(localTelemetryProvider));
});

/// FR-10~13：贴纸贴附、属性并入标签、按实例精确撤销。
class StickerApplication {
  const StickerApplication(this._repos, this._telemetry);

  final AppRepositories _repos;
  final TelemetrySink _telemetry;

  Future<String> apply({
    required String entryId,
    required BuiltinSticker sticker,
  }) async {
    final instanceId = const Uuid().v4();
    final transform = jsonEncode(<String, Object?>{
      'x': 0.5,
      'y': 0.5,
      'scale': 1.0,
      'rotation': 0.0,
      'z': 0,
    });

    // 冗余快照：主记录软删后历史实例照常渲染/统计（DQ-08）。
    await _repos.stickers.applyInstance(
      StickerInstanceRow(
        id: instanceId,
        entryId: entryId,
        stickerId: sticker.id,
        assetPathSnapshot: sticker.assetPath,
        attributesSnapshotJson: jsonEncode(sticker.attributes),
        transformJson: transform,
        zOrder: 0,
      ),
    );

    var merged = 0;
    for (final attribute in sticker.attributes) {
      final tagId = await _repos.tags.ensureTag(attribute);
      await _repos.tags.addTagToEntry(
        EntryTagRow(
          entryId: entryId,
          tagId: tagId,
          source: TagSources.sticker,
          confidence: 0.85,
          stickerInstanceId: instanceId,
        ),
      );
      merged++;
    }

    await _telemetry.track(
      TelemetryEventNames.stickerApply,
      TelemetryEvents.stickerApply(
        stickerSource: sticker.assetPath,
        action: 'apply',
        tagMergedCount: merged,
      ),
    );
    return instanceId;
  }

  /// FR-11：撤销只回滚 source=贴纸 且来自该实例的标签，不误删同名文本标签。
  Future<void> undo({
    required String entryId,
    required String instanceId,
    required String stickerSource,
  }) async {
    await _repos.stickers.undoInstance(instanceId);
    await _repos.tags.removeTagsByStickerInstance(entryId, instanceId);
    await _telemetry.track(
      TelemetryEventNames.stickerApply,
      TelemetryEvents.stickerApply(
        stickerSource: stickerSource,
        action: 'undo',
        tagMergedCount: 0,
      ),
    );
  }
}
