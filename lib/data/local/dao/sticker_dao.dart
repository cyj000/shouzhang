import 'package:drift/drift.dart';

import '../../models/records.dart';
import '../database.dart';
import 'base_dao.dart';

/// stickers + sticker_sources + sticker_instances DAO（FR-14~20）。
class StickerDao extends BaseDao {
  StickerDao(super.db);

  Future<void> insertSticker(StickerRow s) async {
    await db.customStatement(
      '''
      INSERT OR REPLACE INTO stickers
        (id, asset_path, attributes_json, source, checksum, removed_at, remove_reason)
      VALUES (?,?,?,?,?,?,?)
      ''',
      <Object?>[
        s.id, s.assetPath, s.attributesJson, s.source, s.checksum,
        s.removedAt, s.removeReason,
      ],
    );
  }

  Future<StickerRow?> findByChecksum(String checksum) async {
    final rows = await (db.select(db.stickers)
          ..where((t) => t.checksum.equals(checksum)))
        .get();
    return rows.isEmpty ? null : StickerRow.fromRow(rows.first);
  }

  /// 预设库查询一律过滤软删（§3.4 / REV-05）。
  Future<List<StickerRow>> activeStickers() async {
    final rows = await (db.select(db.stickers)
          ..where((t) => t.removedAt.isNull())
          ..orderBy(<OrderingTerm Function(Stickers)>[
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
    return rows.map(StickerRow.fromRow).toList();
  }

  /// REV-05：软删 + 原因；历史实例靠快照继续渲染（DQ-08）。
  Future<void> softDelete(String id, int nowMs, String reason) async {
    await db.customStatement(
      'UPDATE stickers SET removed_at=?, remove_reason=? WHERE id=?',
      <Object?>[nowMs, reason, id],
    );
  }

  Future<void> insertSource(StickerSourceRow source) async {
    await db.customStatement(
      '''
      INSERT OR REPLACE INTO sticker_sources
        (sticker_id, source_url, license, obtained_at, author, license_check_shot)
      VALUES (?,?,?,?,?,?)
      ''',
      <Object?>[
        source.stickerId, source.sourceUrl, source.license,
        source.obtainedAt, source.author, source.licenseCheckShot,
      ],
    );
  }

  Future<StickerSourceRow?> sourceOf(String stickerId) async {
    final rows = await (db.select(db.stickerSources)
          ..where((t) => t.stickerId.equals(stickerId)))
        .get();
    return rows.isEmpty ? null : StickerSourceRow.fromRow(rows.first);
  }

  Future<void> insertInstance(StickerInstanceRow instance) async {
    await db.customStatement(
      '''
      INSERT INTO sticker_instances
        (id, entry_id, sticker_id, asset_path_snapshot,
         attributes_snapshot_json, transform_json, z_order)
      VALUES (?,?,?,?,?,?,?)
      ''',
      <Object?>[
        instance.id, instance.entryId, instance.stickerId,
        instance.assetPathSnapshot, instance.attributesSnapshotJson,
        instance.transformJson, instance.zOrder,
      ],
    );
  }

  Future<List<StickerInstanceRow>> instancesForEntry(String entryId) async {
    final rows = await (db.select(db.stickerInstances)
          ..where((t) => t.entryId.equals(entryId))
          ..orderBy(<OrderingTerm Function(StickerInstances)>[
            (t) => OrderingTerm.asc(t.zOrder),
          ]))
        .get();
    return rows.map(StickerInstanceRow.fromRow).toList();
  }

  /// FR-11：撤销贴纸精确删除该实例的关联（由调用方限定 source=贴纸）。
  Future<void> deleteInstance(String instanceId) async {
    await db.customStatement(
      'DELETE FROM sticker_instances WHERE id=?',
      <Object?>[instanceId],
    );
  }

  Future<int> purgeRemoved(int cutoffMs) async {
    final countRow = await db.customSelect(
      'SELECT COUNT(*) AS c FROM stickers WHERE removed_at IS NOT NULL AND removed_at < ?',
      variables: <Variable<Object?>>[Variable<int>(cutoffMs)],
    ).getSingle();
    final count = countRow.read<int>('c');
    if (count > 0) {
      await db.customStatement(
        'DELETE FROM stickers WHERE removed_at IS NOT NULL AND removed_at < ?',
        <Object?>[cutoffMs],
      );
    }
    return count;
  }
}
