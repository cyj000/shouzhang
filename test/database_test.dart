import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paper_ledger/data/local/dao/oplog_dao.dart';
import 'package:paper_ledger/data/local/database.dart';
import 'package:paper_ledger/data/models/records.dart';
import 'package:paper_ledger/domain/entities/constants.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('§3 全部 9 张表齐全', () async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='table'",
        )
        .get();
    final names = rows.map((row) => row.read<String>('name')).toList();
    expect(
      names,
      containsAll(<String>[
        'entries',
        'tags',
        'entry_tags',
        'stickers',
        'sticker_sources',
        'sticker_instances',
        'ink_layers',
        'oplog',
        'telemetry_events',
      ]),
    );
  });

  test('系统标签 未分类 已种子化且不可删口径存在', () async {
    final rows = await db.customSelect(
      'SELECT id, name, type, is_system FROM tags WHERE name = ?',
      variables: <Variable<Object>>[Variable<String>(SystemTags.unclassifiedName)],
    ).get();
    expect(rows.length, 1);
    expect(TagRow.fromRow(rows.first).isSystem, isTrue);
  });

  test('entries 软删过滤：常规查询不带 tombstone', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.customStatement(
      '''
      INSERT INTO entries (id, type, amount_cents, occurred_at, revision, deleted,
        amount_version, note_version, tags_version, stickers_version, ink_version,
        created_at, updated_at)
      VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
      ''',
      <Object?>['e1', 'expense', 30, now, 0, 0, 0, 0, 0, 0, 0, now, now],
    );
    await db.customStatement(
      '''
      INSERT INTO entries (id, type, amount_cents, occurred_at, revision, deleted,
        amount_version, note_version, tags_version, stickers_version, ink_version,
        created_at, updated_at)
      VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
      ''',
      <Object?>['e2', 'expense', 10, now, 0, 1, 0, 0, 0, 0, 0, now, now],
    );

    final active = await db.customSelect(
      'SELECT id FROM entries WHERE deleted = 0',
    ).get();
    expect(active.length, 1);
    expect(active.first.read<String>('id'), 'e1');
  });

  test('oplog 幂等键 (op_id, device_id) 重复写只保留一条', () async {
    final dao = OplogDao(db);
    final row = OplogRow(
      opId: 'op-1',
      deviceId: 'dev-a',
      entity: 'entries',
      opType: 'create',
      payloadJson: '{}',
      lamport: 1,
      createdAt: 1,
    );
    await dao.append(row);
    await dao.append(row);
    expect((await dao.all()).length, 1);
  });

  test('金额按分单位整数存储，更新时 revision +1', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    const entry = EntryRow(
      id: 'e-rev',
      amountCents: 30, // 0.30 元
      occurredAt: 1,
      createdAt: 1,
      updatedAt: 1,
    );
    await db.customStatement(
      '''
      INSERT INTO entries (id, type, amount_cents, occurred_at, revision, deleted,
        amount_version, note_version, tags_version, stickers_version, ink_version,
        created_at, updated_at)
      VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
      ''',
      <Object?>[
        entry.id, entry.type, entry.amountCents, entry.occurredAt, 0, 0,
        0, 0, 0, 0, 0, entry.createdAt, entry.updatedAt,
      ],
    );
    await db.customStatement(
      'UPDATE entries SET amount_cents=?, revision=revision+1, updated_at=? WHERE id=?',
      <Object?>[10, now, entry.id],
    );

    final rows = await db.customSelect(
      'SELECT * FROM entries WHERE id = ?',
      variables: <Variable<Object>>[Variable<String>(entry.id)],
    ).get();
    final updated = EntryRow.fromRow(rows.first);
    expect(updated.amountCents, isA<int>());
    expect(updated.amountCents, 10);
    expect(updated.revision, 1);
  });
}
