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
    final rows = await (db.select(db.telemetryEvents)
          ..where((t) => t.eventName.equals(eventName))
          ..orderBy(<OrderingTerm Function(TelemetryEvents)>[
            (t) => OrderingTerm.asc(t.ts),
          ]))
        .get();
    return rows.map(TelemetryEventRow.fromRow).toList();
  }
}
