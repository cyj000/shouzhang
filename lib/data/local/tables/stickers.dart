import 'package:drift/drift.dart';

/// stickers（贴纸主记录 / 预设库）—— 任务书 §3.4。
/// 查询预设库一律 `removedAt IS NULL`（REV-05 软删除）。
class Stickers extends Table {
  TextColumn get id => text()();
  TextColumn get assetPath => text()();
  TextColumn get attributesJson => text()();
  TextColumn get source => text()();
  TextColumn get checksum => text()();
  IntColumn get removedAt => integer().nullable()();
  TextColumn get removeReason => text().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{id};

  @override
  List<Index> get indexes => <Index>[
        Index(
          'uq_stickers_checksum',
          'CREATE UNIQUE INDEX uq_stickers_checksum ON stickers (checksum)',
        ),
        Index(
          'idx_stickers_removed_at',
          'CREATE INDEX idx_stickers_removed_at ON stickers (removed_at)',
        ),
      ];
}
