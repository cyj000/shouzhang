import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../domain/entities/constants.dart';
import '../local/database.dart';
import '../local/dao/entry_dao.dart';
import '../local/dao/ink_dao.dart';
import '../local/dao/oplog_dao.dart';
import '../local/dao/sticker_dao.dart';
import '../local/dao/tag_dao.dart';
import '../local/dao/telemetry_dao.dart';
import '../models/records.dart';

/// 仓库容器：业务与数据源隔离（§2.1 / §2.3）。UI 只经 provider 访问这里。
class AppRepositories {
  AppRepositories(this.db, {required String deviceId}) {
    oplog = OplogRepository(db, deviceId: deviceId);
    entries = EntryRepository(db, oplog);
    tags = TagRepository(db, oplog);
    stickers = StickerRepository(db, oplog);
    ink = InkRepository(db, oplog);
    telemetry = TelemetryRepository(db);
  }

  final AppDatabase db;
  late final OplogRepository oplog;
  late final EntryRepository entries;
  late final TagRepository tags;
  late final StickerRepository stickers;
  late final InkRepository ink;
  late final TelemetryRepository telemetry;

  Future<void> close() => db.close();
}

/// oplog 本地写入：幂等键 (opId, deviceId)，一期不上报（FR-26 / R1）。
class OplogRepository {
  OplogRepository(this._db, {required this.deviceId})
      : _dao = OplogDao(_db);

  final AppDatabase _db;
  final OplogDao _dao;
  final String deviceId;
  int _lamport = 0;

  Future<void> append(String entity, String opType, Object? payload) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _dao.append(
      OplogRow(
        opId: const Uuid().v4(),
        deviceId: deviceId,
        entity: entity,
        opType: opType,
        payloadJson: jsonEncode(payload ?? <String, Object?>{}),
        lamport: ++_lamport,
        createdAt: now,
      ),
    );
  }

  Future<List<OplogRow>> all() => _dao.all();
}

/// 账目仓库（FR-01~06 / FR-25）。
class EntryRepository {
  EntryRepository(this._db, this._oplog) : _dao = EntryDao(_db);

  final AppDatabase _db;
  final EntryDao _dao;
  final OplogRepository _oplog;

  Future<void> save(EntryRow entry) async {
    final exists = await _dao.findById(entry.id) != null;
    if (exists) {
      await _dao.updateEntry(entry);
      await _oplog.append('entries', 'update', <String, Object?>{'id': entry.id});
    } else {
      await _dao.insert(entry);
      await _oplog.append('entries', 'create', <String, Object?>{'id': entry.id});
    }
  }

  Future<EntryRow?> findById(String id) => _dao.findById(id);

  Stream<List<EntryRow>> watchActive() => _dao.watchActive();

  Future<List<EntryRow>> activeInRange(int fromMs, int toMs) =>
      _dao.activeInRange(fromMs, toMs);

  Future<void> softDelete(String id) async {
    await _dao.softDelete(id, DateTime.now().millisecondsSinceEpoch);
    await _oplog.append('entries', 'delete', <String, Object?>{'id': id});
  }

  /// DQ-05：清理超过 90 天的 tombstone（前台检查 / WorkManager 调度）。
  Future<int> purgeTombstones() {
    final cutoff = DateTime.now()
        .subtract(const Duration(days: RetentionRules.tombstoneDays))
        .millisecondsSinceEpoch;
    return _dao.purgeTombstones(cutoff);
  }
}

/// 标签仓库（FR-07~09 / FR-11）。
class TagRepository {
  TagRepository(this._db, this._oplog) : _dao = TagDao(_db);

  final AppDatabase _db;
  final TagDao _dao;
  final OplogRepository _oplog;

  Future<String> ensureTag(String name, {String? type}) async {
    final id = await _dao.ensureTag(name, type: type);
    await _oplog.append('tags', 'ensure', <String, Object?>{'name': name});
    return id;
  }

  Future<List<TagRow>> allTags() => _dao.allTags();

  Future<List<TagRow>> tagsForEntry(String entryId) =>
      _dao.tagsForEntry(entryId);

  Future<List<EntryTagRow>> relationsForEntry(String entryId) =>
      _dao.relationsForEntry(entryId);

  Future<void> addTagToEntry(EntryTagRow relation) async {
    await _dao.addEntryTag(relation);
    await _oplog.append('entry_tags', 'create', <String, Object?>{
      'entry_id': relation.entryId,
      'tag_id': relation.tagId,
      'source': relation.source,
    });
  }

  /// FR-11：撤销贴纸只回滚 source=贴纸 的同名标签，不误删文本来源。
  Future<void> removeEntryTag(
    String entryId,
    String tagId, {
    String? source,
  }) async {
    await _dao.removeEntryTag(entryId, tagId, source: source);
    await _oplog.append('entry_tags', 'delete', <String, Object?>{
      'entry_id': entryId,
      'tag_id': tagId,
      'source': source,
    });
  }

  Future<List<String>> unclassifiedEntryIds() => _dao.unclassifiedEntryIds();

  /// FR-11：撤销贴纸精确回滚 source=贴纸 且来源于该实例的标签。
  Future<void> removeTagsByStickerInstance(
    String entryId,
    String instanceId,
  ) async {
    await _dao.removeByStickerInstance(entryId, instanceId);
    await _oplog.append('entry_tags', 'delete_by_instance', <String, Object?>{
      'entry_id': entryId,
      'sticker_instance_id': instanceId,
    });
  }

  /// FR-09：系统标签（未分类）不可删。
  Future<bool> deleteTagIfMutable(String id) async {
    if (id == SystemTags.unclassifiedId || await _dao.isSystemTag(id)) {
      return false;
    }
    await _db.customStatement('DELETE FROM tags WHERE id=?', <Object?>[id]);
    await _oplog.append('tags', 'delete', <String, Object?>{'id': id});
    return true;
  }
}

/// 贴纸仓库（FR-14~20）。许可校验在 feature/sticker 的导入器完成（PKG-05）。
class StickerRepository {
  StickerRepository(this._db, this._oplog)
      : _dao = StickerDao(_db);

  final AppDatabase _db;
  final StickerDao _dao;
  final OplogRepository _oplog;

  Future<StickerRow?> findByChecksum(String checksum) =>
      _dao.findByChecksum(checksum);

  Future<List<StickerRow>> activeStickers() => _dao.activeStickers();

  Future<void> saveSticker(StickerRow sticker) async {
    await _dao.insertSticker(sticker);
    await _oplog.append('stickers', 'upsert', <String, Object?>{'id': sticker.id});
  }

  Future<void> saveSource(StickerSourceRow source) =>
      _dao.insertSource(source);

  Future<StickerSourceRow?> sourceOf(String stickerId) =>
      _dao.sourceOf(stickerId);

  Future<void> applyInstance(StickerInstanceRow instance) async {
    await _dao.insertInstance(instance);
    await _oplog.append(
      'sticker_instances',
      'create',
      <String, Object?>{'id': instance.id, 'entry_id': instance.entryId},
    );
  }

  Future<List<StickerInstanceRow>> instancesForEntry(String entryId) =>
      _dao.instancesForEntry(entryId);

  /// FR-11：撤销贴纸实例。
  Future<void> undoInstance(String instanceId) async {
    await _dao.deleteInstance(instanceId);
    await _oplog.append(
      'sticker_instances',
      'delete',
      <String, Object?>{'id': instanceId},
    );
  }

  Future<void> softDelete(String id, String reason) async {
    await _dao.softDelete(
      id,
      DateTime.now().millisecondsSinceEpoch,
      reason,
    );
    await _oplog.append(
      'stickers',
      'soft_delete',
      <String, Object?>{'id': id, 'reason': reason},
    );
  }

  Future<int> purgeRemoved() {
    final cutoff = DateTime.now()
        .subtract(const Duration(days: RetentionRules.tombstoneDays))
        .millisecondsSinceEpoch;
    return _dao.purgeRemoved(cutoff);
  }
}

/// 涂鸦仓库（FR-12）。
class InkRepository {
  InkRepository(this._db, this._oplog) : _dao = InkDao(_db);

  final AppDatabase _db;
  final InkDao _dao;
  final OplogRepository _oplog;

  Future<void> saveInk(InkLayerRow layer) async {
    await _dao.saveInk(layer);
    await _oplog.append('ink_layers', 'upsert', <String, Object?>{
      'id': layer.id,
      'entry_id': layer.entryId,
    });
  }

  Future<List<InkLayerRow>> layersForEntry(String entryId) =>
      _dao.layersForEntry(entryId);
}

/// 埋点仓库：仅本地落库（R7）。
class TelemetryRepository {
  TelemetryRepository(this._db) : _dao = TelemetryDao(_db);

  final AppDatabase _db;
  final TelemetryDao _dao;

  Future<void> track(
    String eventName,
    Map<String, Object?> payload, {
    int? ts,
  }) =>
      _dao.log(
        eventName,
        payload,
        ts: ts ?? DateTime.now().millisecondsSinceEpoch,
      );

  Future<List<TelemetryEventRow>> events(String eventName) =>
      _dao.eventsByName(eventName);
}
