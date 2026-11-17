import 'package:drift/drift.dart';

import '../../models/records.dart';
import '../database.dart';
import 'base_dao.dart';

/// oplog DAO（FR-26 / FR-40）。
/// 幂等键 (op_id, device_id)：重复写同一操作静默忽略，一期不上报（R1）。
class OplogDao extends BaseDao {
  OplogDao(super.db);

  Future<void> append(OplogRow op) async {
    await db.customStatement(
      '''
      INSERT OR IGNORE INTO oplog
        (op_id, device_id, entity, op_type, payload_json, lamport, created_at)
      VALUES (?,?,?,?,?,?,?)
      ''',
      <Object?>[
        op.opId, op.deviceId, op.entity, op.opType,
        op.payloadJson, op.lamport, op.createdAt,
      ],
    );
  }

  Future<List<OplogRow>> all() async {
    final rows = await (db.select(db.oplog)
          ..orderBy(<OrderingTerm Function(Oplog)>[
            (t) => OrderingTerm.asc(t.lamport),
          ]))
        .get();
    return rows.map(OplogRow.fromRow).toList();
  }
}
