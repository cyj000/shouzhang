import 'package:drift/drift.dart';

/// entry_tags（账目标签关联）—— 任务书 §3.3。
/// source 决定撤销语义：撤销贴纸仅回滚 source=贴纸 的关联（FR-11）。
class EntryTags extends Table {
  TextColumn get entryId => text()();
  TextColumn get tagId => text()();
  TextColumn get source => text()();
  RealColumn get confidence => real().withDefault(const Constant(1.0))();
  TextColumn get stickerInstanceId => text().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{entryId, tagId, source};

  @override
  List<Index> get indexes => <Index>[
        Index(
          'idx_entry_tags_entry',
          'CREATE INDEX idx_entry_tags_entry ON entry_tags (entry_id)',
        ),
        Index(
          'idx_entry_tags_tag',
          'CREATE INDEX idx_entry_tags_tag ON entry_tags (tag_id)',
        ),
      ];
}
