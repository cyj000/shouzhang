import 'package:drift/drift.dart';

/// tags（标签）—— 任务书 §3.2。name 唯一；`未分类` 为系统保留标签，不可删/改名（FR-09）。
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text().nullable()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => <Column>{id};

  @override
  List<Index> get indexes => <Index>[
        Index(
          'uq_tags_name',
          'CREATE UNIQUE INDEX uq_tags_name ON tags (name)',
        ),
      ];
}
