import 'package:drift/drift.dart';

/// 数据记录（手写不可变类，避免引入 build_runner 生成文件）。
/// 所有写入经 DAO/Repository 参数化执行，UI 层禁止访问此类以外的原始 Row。

class EntryRow {
  const EntryRow({
    required this.id,
    required this.amountCents,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.type = 'expense',
    this.note,
    this.paymentMethod,
    this.locationLat,
    this.locationLng,
    this.locationCity,
    this.revision = 0,
    this.deleted = false,
    this.amountVersion = 0,
    this.amountHash,
    this.noteVersion = 0,
    this.noteHash,
    this.tagsVersion = 0,
    this.tagsHash,
    this.stickersVersion = 0,
    this.stickersHash,
    this.inkVersion = 0,
    this.inkHash,
  });

  final String id;
  final String type;
  final int amountCents; // 分单位整数（R2）
  final String? note;
  final int occurredAt;
  final String? paymentMethod;
  final double? locationLat; // 一期预留留空
  final double? locationLng;
  final String? locationCity;
  final int revision;
  final bool deleted;
  final int amountVersion;
  final int? amountHash;
  final int noteVersion;
  final int? noteHash;
  final int tagsVersion;
  final int? tagsHash;
  final int stickersVersion;
  final int? stickersHash;
  final int inkVersion;
  final int? inkHash;
  final int createdAt;
  final int updatedAt;

  factory EntryRow.fromRow(Row row) => EntryRow(
        id: row.read<String>('id'),
        type: row.read<String>('type'),
        amountCents: row.read<int>('amount_cents'),
        note: row.read<String?>('note'),
        occurredAt: row.read<int>('occurred_at'),
        paymentMethod: row.read<String?>('payment_method'),
        locationLat: row.read<double?>('location_lat'),
        locationLng: row.read<double?>('location_lng'),
        locationCity: row.read<String?>('location_city'),
        revision: row.read<int>('revision'),
        deleted: row.read<bool>('deleted'),
        amountVersion: row.read<int>('amount_version'),
        amountHash: row.read<int?>('amount_hash'),
        noteVersion: row.read<int>('note_version'),
        noteHash: row.read<int?>('note_hash'),
        tagsVersion: row.read<int>('tags_version'),
        tagsHash: row.read<int?>('tags_hash'),
        stickersVersion: row.read<int>('stickers_version'),
        stickersHash: row.read<int?>('stickers_hash'),
        inkVersion: row.read<int>('ink_version'),
        inkHash: row.read<int?>('ink_hash'),
        createdAt: row.read<int>('created_at'),
        updatedAt: row.read<int>('updated_at'),
      );
}

class TagRow {
  const TagRow({
    required this.id,
    required this.name,
    this.type,
    this.isSystem = false,
  });

  final String id;
  final String name;
  final String? type;
  final bool isSystem;

  factory TagRow.fromRow(Row row) => TagRow(
        id: row.read<String>('id'),
        name: row.read<String>('name'),
        type: row.read<String?>('type'),
        isSystem: row.read<bool>('is_system'),
      );
}

class EntryTagRow {
  const EntryTagRow({
    required this.entryId,
    required this.tagId,
    required this.source,
    required this.confidence,
    this.stickerInstanceId,
  });

  final String entryId;
  final String tagId;
  final String source; // 文本 / 贴纸 / 历史 / 手动
  final double confidence;
  final String? stickerInstanceId;

  factory EntryTagRow.fromRow(Row row) => EntryTagRow(
        entryId: row.read<String>('entry_id'),
        tagId: row.read<String>('tag_id'),
        source: row.read<String>('source'),
        confidence: row.read<double>('confidence'),
        stickerInstanceId: row.read<String?>('sticker_instance_id'),
      );
}

class StickerRow {
  const StickerRow({
    required this.id,
    required this.assetPath,
    required this.attributesJson,
    required this.source,
    required this.checksum,
    this.removedAt,
    this.removeReason,
  });

  final String id;
  final String assetPath;
  final String attributesJson;
  final String source; // 一期固定 `开源预设`
  final String checksum;
  final int? removedAt;
  final String? removeReason;

  factory StickerRow.fromRow(Row row) => StickerRow(
        id: row.read<String>('id'),
        assetPath: row.read<String>('asset_path'),
        attributesJson: row.read<String>('attributes_json'),
        source: row.read<String>('source'),
        checksum: row.read<String>('checksum'),
        removedAt: row.read<int?>('removed_at'),
        removeReason: row.read<String?>('remove_reason'),
      );
}

class StickerSourceRow {
  const StickerSourceRow({
    required this.stickerId,
    required this.sourceUrl,
    required this.license,
    required this.obtainedAt,
    required this.licenseCheckShot,
    this.author,
  });

  final String stickerId;
  final String sourceUrl;
  final String license; // 仅 CC0 / CC BY
  final int obtainedAt;
  final String? author;
  final String licenseCheckShot;

  factory StickerSourceRow.fromRow(Row row) => StickerSourceRow(
        stickerId: row.read<String>('sticker_id'),
        sourceUrl: row.read<String>('source_url'),
        license: row.read<String>('license'),
        obtainedAt: row.read<int>('obtained_at'),
        author: row.read<String?>('author'),
        licenseCheckShot: row.read<String>('license_check_shot'),
      );
}

class StickerInstanceRow {
  const StickerInstanceRow({
    required this.id,
    required this.entryId,
    required this.stickerId,
    required this.assetPathSnapshot,
    required this.attributesSnapshotJson,
    required this.transformJson,
    required this.zOrder,
  });

  final String id;
  final String entryId;
  final String stickerId;
  final String assetPathSnapshot;
  final String attributesSnapshotJson;
  final String transformJson;
  final int zOrder;

  factory StickerInstanceRow.fromRow(Row row) => StickerInstanceRow(
        id: row.read<String>('id'),
        entryId: row.read<String>('entry_id'),
        stickerId: row.read<String>('sticker_id'),
        assetPathSnapshot: row.read<String>('asset_path_snapshot'),
        attributesSnapshotJson:
            row.read<String>('attributes_snapshot_json'),
        transformJson: row.read<String>('transform_json'),
        zOrder: row.read<int>('z_order'),
      );
}

class InkLayerRow {
  const InkLayerRow({
    required this.id,
    required this.entryId,
    required this.strokesJson,
  });

  final String id;
  final String entryId;
  final String strokesJson; // 增量笔迹指令数组

  factory InkLayerRow.fromRow(Row row) => InkLayerRow(
        id: row.read<String>('id'),
        entryId: row.read<String>('entry_id'),
        strokesJson: row.read<String>('strokes_json'),
      );
}

class OplogRow {
  const OplogRow({
    required this.opId,
    required this.deviceId,
    required this.entity,
    required this.opType,
    required this.payloadJson,
    required this.lamport,
    required this.createdAt,
  });

  final String opId;
  final String deviceId;
  final String entity;
  final String opType;
  final String payloadJson;
  final int lamport;
  final int createdAt;

  factory OplogRow.fromRow(Row row) => OplogRow(
        opId: row.read<String>('op_id'),
        deviceId: row.read<String>('device_id'),
        entity: row.read<String>('entity'),
        opType: row.read<String>('op_type'),
        payloadJson: row.read<String>('payload_json'),
        lamport: row.read<int>('lamport'),
        createdAt: row.read<int>('created_at'),
      );
}

class TelemetryEventRow {
  const TelemetryEventRow({
    this.id,
    required this.eventName,
    required this.payloadJson,
    required this.ts,
  });

  final int? id;
  final String eventName;
  final String payloadJson;
  final int ts;

  factory TelemetryEventRow.fromRow(Row row) => TelemetryEventRow(
        id: row.read<int>('id'),
        eventName: row.read<String>('event_name'),
        payloadJson: row.read<String>('payload_json'),
        ts: row.read<int>('ts'),
      );
}
