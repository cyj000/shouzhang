import 'package:drift/drift.dart';

/// entries（账目）—— 对应 PRD v1.4 §9.1 / 任务书 §3.1。
///
/// FR-25/26：金额一律 INTEGER 分；软删 tombstone；预留五块冲突字段（二期用）。
class Entries extends Table {
  TextColumn get id => text()();
  TextColumn get type => text().withDefault(const Constant('expense'))();
  IntColumn get amountCents => integer()();
  TextColumn get note => text().nullable()();
  IntColumn get occurredAt => integer()();
  TextColumn get paymentMethod => text().nullable()();

  // 一期预留留空：不采集、不申请定位权限（FR / R4）。
  RealColumn get locationLat => real().nullable()();
  RealColumn get locationLng => real().nullable()();
  TextColumn get locationCity => text().nullable()();

  IntColumn get revision => integer().withDefault(const Constant(0))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  // —— 五块冲突字段预留（金额/备注/标签/贴纸/笔迹），二期冲突检测用，一期不合并 ——
  IntColumn get amountVersion => integer().withDefault(const Constant(0))();
  IntColumn get amountHash => integer().nullable()();
  IntColumn get noteVersion => integer().withDefault(const Constant(0))();
  IntColumn get noteHash => integer().nullable()();
  IntColumn get tagsVersion => integer().withDefault(const Constant(0))();
  IntColumn get tagsHash => integer().nullable()();
  IntColumn get stickersVersion => integer().withDefault(const Constant(0))();
  IntColumn get stickersHash => integer().nullable()();
  IntColumn get inkVersion => integer().withDefault(const Constant(0))();
  IntColumn get inkHash => integer().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => <Column>{id};

  @override
  List<Index> get indexes => <Index>[
        Index(
          'idx_entries_occurred_at',
          'CREATE INDEX idx_entries_occurred_at ON entries (occurred_at)',
        ),
        Index(
          'idx_entries_type',
          'CREATE INDEX idx_entries_type ON entries (type)',
        ),
        Index(
          'idx_entries_deleted',
          'CREATE INDEX idx_entries_deleted ON entries (deleted)',
        ),
      ];
}
