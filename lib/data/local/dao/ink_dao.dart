import 'package:drift/drift.dart';

import '../../models/records.dart';
import '../database.dart';
import 'base_dao.dart';

/// ink_layers DAO（FR-12：增量笔迹指令数组）。
class InkDao extends BaseDao {
  InkDao(super.db);

  Future<void> saveInk(InkLayerRow layer) async {
    await db.customStatement(
      '''
      INSERT INTO ink_layers (id, entry_id, strokes_json) VALUES (?,?,?)
      ON CONFLICT(id) DO UPDATE SET strokes_json=excluded.strokes_json
      ''',
      <Object?>[layer.id, layer.entryId, layer.strokesJson],
    );
  }

  Future<List<InkLayerRow>> layersForEntry(String entryId) async {
    final rows = await db.customSelect(
      'SELECT id, entry_id, strokes_json FROM ink_layers WHERE entry_id = ?',
      variables: <Variable<Object>>[Variable<String>(entryId)],
    ).get();
    return rows.map(InkLayerRow.fromRow).toList();
  }

  Future<void> deleteLayer(String id) async {
    await db.customStatement('DELETE FROM ink_layers WHERE id=?', <Object?>[id]);
  }
}
