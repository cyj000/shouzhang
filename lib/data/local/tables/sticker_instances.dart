import 'package:drift/drift.dart';

/// sticker_instances（贴纸实例）—— 任务书 §3.6。
/// assetPathSnapshot / attributesSnapshotJson 为冗余快照，防软删后断链（DQ-08）。
class StickerInstances extends Table {
  TextColumn get id => text()();
  TextColumn get entryId => text()();
  TextColumn get stickerId => text()();
  TextColumn get assetPathSnapshot => text()();
  TextColumn get attributesSnapshotJson => text()();
  TextColumn get transformJson => text()();
  IntColumn get zOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => <Column>{id};

  @override
  List<Index> get indexes => <Index>[
        Index(
          'idx_sticker_instances_entry',
          'CREATE INDEX idx_sticker_instances_entry ON sticker_instances (entry_id)',
        ),
      ];
}
