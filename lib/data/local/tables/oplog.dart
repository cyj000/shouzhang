import 'package:drift/drift.dart';

/// oplog（同步预埋）—— 任务书 §3.8。
/// 幂等键 = (opId, deviceId)。一期仅本地写入，不上报、不合并（R1 / FR-26 / FR-40）。
class Oplog extends Table {
  TextColumn get opId => text()();
  TextColumn get deviceId => text()();
  TextColumn get entity => text()();
  TextColumn get opType => text()();
  TextColumn get payloadJson => text()();
  IntColumn get lamport => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => <Column>{opId, deviceId};

  @override
  String get tableName => 'oplog';
}
