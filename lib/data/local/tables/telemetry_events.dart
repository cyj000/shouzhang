import 'package:drift/drift.dart';

/// telemetry_events（埋点本地表）—— 任务书 §3.9 / 第 6 章事件字典。
/// 一期仅本地落库，禁止任何外发网络请求（R7）。
class TelemetryEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventName => text()();
  TextColumn get payloadJson => text()();
  IntColumn get ts => integer()();
}
