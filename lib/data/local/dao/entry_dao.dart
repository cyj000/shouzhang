import 'package:drift/drift.dart';

import '../../models/records.dart';
import '../database.dart';
import 'base_dao.dart';

/// entries DAO（FR-01~06 / FR-25）。
class EntryDao extends BaseDao {
  EntryDao(super.db);

  static const String _columns = '''
    id, type, amount_cents, note, occurred_at, payment_method,
    location_lat, location_lng, location_city, revision, deleted,
    amount_version, amount_hash, note_version, note_hash,
    tags_version, tags_hash, stickers_version, stickers_hash,
    ink_version, ink_hash, created_at, updated_at
  ''';

  Future<void> insert(EntryRow e) async {
    await db.customStatement(
      'INSERT INTO entries ($_columns) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
      <Object?>[
        e.id, e.type, e.amountCents, e.note, e.occurredAt, e.paymentMethod,
        e.locationLat, e.locationLng, e.locationCity, e.revision,
        e.deleted ? 1 : 0, e.amountVersion, e.amountHash, e.noteVersion,
        e.noteHash, e.tagsVersion, e.tagsHash, e.stickersVersion,
        e.stickersHash, e.inkVersion, e.inkHash, e.createdAt, e.updatedAt,
      ],
    );
  }

  /// 更新整条账目：revision 每次 +1（§3.1），二期冲突检测用。
  Future<void> updateEntry(EntryRow e) async {
    await db.customStatement(
      '''
      UPDATE entries SET type=?, amount_cents=?, note=?, occurred_at=?,
        payment_method=?, revision=revision+1, deleted=?, amount_version=?, amount_hash=?,
        note_version=?, note_hash=?, tags_version=?, tags_hash=?,
        stickers_version=?, stickers_hash=?, ink_version=?, ink_hash=?, updated_at=?
      WHERE id=?
      ''',
      <Object?>[
        e.type, e.amountCents, e.note, e.occurredAt, e.paymentMethod,
        e.deleted ? 1 : 0, e.amountVersion, e.amountHash,
        e.noteVersion, e.noteHash, e.tagsVersion, e.tagsHash,
        e.stickersVersion, e.stickersHash, e.inkVersion, e.inkHash,
        e.updatedAt, e.id,
      ],
    );
  }

  Future<EntryRow?> findById(String id) async {
    final rows = await (db.select(db.entries)
          ..where((t) => t.id.equals(id)))
        .get();
    return rows.isEmpty ? null : EntryRow.fromRow(rows.first);
  }

  /// 软删过滤：所有常规查询必须带 deleted = 0（§3.10 / REV-05）。
  Stream<List<EntryRow>> watchActive() {
    return (db.select(db.entries)
          ..where((t) => t.deleted.equals(false))
          ..orderBy(<OrderingTerm Function(Entries)>[
            (t) => OrderingTerm.desc(t.occurredAt),
          ]))
        .watch()
        .map((rows) => rows.map(EntryRow.fromRow).toList());
  }

  Future<List<EntryRow>> activeInRange(int fromMs, int toMs) async {
    final rows = await (db.select(db.entries)
          ..where((t) => t.deleted.equals(false) & t.occurredAt.isBetweenValues(fromMs, toMs))
          ..orderBy(<OrderingTerm Function(Entries)>[
            (t) => OrderingTerm.desc(t.occurredAt),
          ]))
        .get();
    return rows.map(EntryRow.fromRow).toList();
  }

  Future<void> softDelete(String id, int nowMs) async {
    await db.customStatement(
      'UPDATE entries SET deleted=1, revision=revision+1, updated_at=? WHERE id=?',
      <Object?>[nowMs, id],
    );
  }

  /// DQ-05：物理清理超过保留期的 tombstone，由前台检查 + WorkManager 调度。
  Future<int> purgeTombstones(int cutoffMs) async {
    final countRow = await db.customSelect(
      'SELECT COUNT(*) AS c FROM entries WHERE deleted=1 AND updated_at < ?',
      variables: <Variable<Object?>>[Variable<int>(cutoffMs)],
    ).getSingle();
    final count = countRow.read<int>('c');
    if (count > 0) {
      await db.customStatement(
        'DELETE FROM entries WHERE deleted=1 AND updated_at < ?',
        <Object?>[cutoffMs],
      );
    }
    return count;
  }
}
