import 'package:drift/drift.dart';

/// ink_layers（涂鸦图层）—— 任务书 §3.7。
/// strokesJson 存增量指令数组（笔迹点位 + 笔刷参数），非整图（FR-12）。
class InkLayers extends Table {
  TextColumn get id => text()();
  TextColumn get entryId => text()();
  TextColumn get strokesJson => text()();

  @override
  Set<Column> get primaryKey => <Column>{id};

  @override
  List<Index> get indexes => <Index>[
        Index(
          'idx_ink_layers_entry',
          'CREATE INDEX idx_ink_layers_entry ON ink_layers (entry_id)',
        ),
      ];
}
