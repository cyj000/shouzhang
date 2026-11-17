import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/records.dart';
import '../database.dart';
import 'base_dao.dart';

/// telemetry_events DAO：仅本地落库，禁止任何网络出口（R7 / 第 6 章）。
class TelemetryDao extends BaseDao {
  TelemetryDao(super.db);

  Future<void> log(
    String eventName,
    Map<String, Object?> payload, {
    required int ts,
  }) async {
    await db.customStatement(
      'INSERT INTO telemetry_events (event_name, payload_json, ts) VALUES (?,?,?)',
      <Object?>[eventName, jsonEncode(payload), ts],
    );
  }

  Future<List<TelemetryEventRow>> eventsByName(String eventName) async {
    final rows = await db.customSelect(
      'SELECT id, event_name, payload_json, ts FROM telemetry_events '
      'WHERE event_name = ? ORDER BY ts ASC',
      variables: <Variable<Object>>[Variable<String>(eventName)],
    ).get();
    return rows.map(TelemetryEventRow.fromRow).toList();
  }
}
