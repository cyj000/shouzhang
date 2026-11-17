import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/constants.dart';
import '../../models/records.dart';
import '../database.dart';
import 'base_dao.dart';

/// tags + entry_tags DAO（FR-07~09 / FR-11）。
class TagDao extends BaseDao {
  TagDao(super.db);

  Future<TagRow?> findByName(String name) async {
    final rows = await db.customSelect(
      'SELECT id, name, type, is_system FROM tags WHERE name = ?',
      variables: <Variable<Object>>[Variable<String>(name)],
    ).get();
    return rows.isEmpty ? null : TagRow.fromRow(rows.first);
  }

  /// 同名标签复用（§3.2 唯一约束 name）。
  Future<String> ensureTag(
    String name, {
    String? type,
    bool isSystem = false,
  }) async {
    final existing = await findByName(name);
    if (existing != null) return existing.id;
    final id = const Uuid().v4();
    await db.customStatement(
      'INSERT OR IGNORE INTO tags (id, name, type, is_system) VALUES (?,?,?,?)',
      <Object?>[id, name, type, isSystem ? 1 : 0],
    );
    return (await findByName(name))?.id ?? id;
  }

  Future<List<TagRow>> allTags() async {
    final rows = await db.customSelect(
      'SELECT id, name, type, is_system FROM tags ORDER BY name ASC',
    ).get();
    return rows.map(TagRow.fromRow).toList();
  }

  Future<TagRow?> findById(String id) async {
    final rows = await db.customSelect(
      'SELECT id, name, type, is_system FROM tags WHERE id = ?',
      variables: <Variable<Object>>[Variable<String>(id)],
    ).get();
    return rows.isEmpty ? null : TagRow.fromRow(rows.first);
  }

  Future<void> addEntryTag(EntryTagRow relation) async {
    await db.customStatement(
      '''
      INSERT OR REPLACE INTO entry_tags
        (entry_id, tag_id, source, confidence, sticker_instance_id)
      VALUES (?,?,?,?,?)
      ''',
      <Object?>[
        relation.entryId,
        relation.tagId,
        relation.source,
        relation.confidence,
        relation.stickerInstanceId,
      ],
    );
  }

  Future<void> removeEntryTag(
    String entryId,
    String tagId, {
    String? source,
  }) async {
    if (source == null) {
      await db.customStatement(
        'DELETE FROM entry_tags WHERE entry_id=? AND tag_id=?',
        <Object?>[entryId, tagId],
      );
    } else {
      await db.customStatement(
        'DELETE FROM entry_tags WHERE entry_id=? AND tag_id=? AND source=?',
        <Object?>[entryId, tagId, source],
      );
    }
  }

  Future<List<EntryTagRow>> relationsForEntry(String entryId) async {
    final rows = await db.customSelect(
      'SELECT entry_id, tag_id, source, confidence, sticker_instance_id '
      'FROM entry_tags WHERE entry_id = ?',
      variables: <Variable<Object>>[Variable<String>(entryId)],
    ).get();
    return rows.map(EntryTagRow.fromRow).toList();
  }

  /// FR-11：按贴纸实例精确回滚，绝不误删文本/历史来源的同名标签。
  Future<void> removeByStickerInstance(
    String entryId,
    String instanceId,
  ) async {
    await db.customStatement(
      '''
      DELETE FROM entry_tags
      WHERE entry_id=? AND sticker_instance_id=? AND source=?
      ''',
      <Object?>[entryId, instanceId, TagSources.sticker],
    );
  }

  Future<List<TagRow>> tagsForEntry(String entryId) async {
    final rows = await db
        .customSelect(
          '''
          SELECT t.* FROM tags t
          INNER JOIN entry_tags et ON et.tag_id = t.id
          WHERE et.entry_id = ?
          ORDER BY et.confidence DESC, t.name ASC
          ''',
          variables: <Variable<Object>>[Variable<String>(entryId)],
        )
        .get();
    return rows.map(TagRow.fromRow).toList();
  }

  /// FR-09：未分类账目 = 无任何标签关联的 active 账目。
  Future<List<String>> unclassifiedEntryIds() async {
    final rows = await db.customSelect(
      '''
      SELECT e.id FROM entries e
      WHERE e.deleted = 0
        AND NOT EXISTS (SELECT 1 FROM entry_tags et WHERE et.entry_id = e.id)
      ORDER BY e.occurred_at DESC
      ''',
    ).get();
    return rows.map((row) => row.read<String>('id')).toList();
  }

  /// FR-09：系统标签禁止删除/改名，调用方需先校验（Repository 兜底）。
  Future<bool> isSystemTag(String id) async {
    final row = await findById(id);
    return row?.isSystem ?? false;
  }
}
