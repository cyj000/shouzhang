import 'dart:convert';

import '../domain/entities/constants.dart';

/// 埋点审计计算（PKG-09 / 第 6 章关键口径）。一期仅本地读取，不外发（R7）。
abstract final class TelemetryAudit {
  /// 命中率 = kept=1 条数 ÷ 有效建议条数（排除「未分类」）。
  /// kept 以保存时刻最终状态为准（删后加回仍算保留）。
  static double hitRate(List<TelemetryEventRowLike> events) {
    final valid = events.where(
      (event) =>
          event.eventName == TelemetryEventNames.classifyTagResult &&
          _kept(event.payload) != null &&
          _tagName(event.payload) != SystemTags.unclassifiedName,
    );
    var keptCount = 0;
    var total = 0;
    for (final event in valid) {
      total++;
      if (_kept(event.payload) == true) keptCount++;
    }
    if (total == 0) return 0.0;
    return keptCount / total;
  }

  /// 事件完整率：必填字段齐全的事件数 / 总事件数。目标 ≥95%。
  static double completeness(List<TelemetryEventRowLike> events) {
    if (events.isEmpty) return 1.0;
    var complete = 0;
    for (final event in events) {
      final required = _requiredFields(event.eventName);
      final payload = event.payload;
      if (required.every(
        (field) => payload.containsKey(field) && payload[field] != null,
      )) {
        complete++;
      }
    }
    return complete / events.length;
  }

  /// 7 日回访率 = 安装后第 7 日仍打开的设备 ÷ 累计安装设备（观察指标，无硬目标）。
  static double day7ReturnRate(List<TelemetryEventRowLike> appOpens) {
    final perDevice = <String, List<int>>{};
    for (final event in appOpens) {
      if (event.eventName != TelemetryEventNames.appOpen) continue;
      final device = event.payload['device_id'] as String?;
      if (device == null) continue;
      perDevice.putIfAbsent(device, () => <int>[]).add(event.ts);
    }
    if (perDevice.isEmpty) return 0.0;
    var returned = 0;
    perDevice.forEach((device, timestamps) {
      timestamps.sort();
      final installDay0 = timestamps.first;
      final day7Start = installDay0 + 7 * 24 * 60 * 60 * 1000;
      final day7End = day7Start + 24 * 60 * 60 * 1000;
      if (timestamps.any(
        (ts) => ts >= day7Start && ts < day7End,
      )) {
        returned++;
      }
    });
    return returned / perDevice.length;
  }

  static List<String> _requiredFields(String eventName) {
    switch (eventName) {
      case TelemetryEventNames.recordStart:
        return const <String>['ts', 'device_id'];
      case TelemetryEventNames.recordSave:
        return const <String>[
          'ts',
          'amount_range',
          'tag_count',
          'duration_ms',
          'offline',
          'entry_index',
          'is_continuous',
        ];
      case TelemetryEventNames.classifyResult:
        return const <String>['ts', 'entry_id', 'tag_count', 'hit'];
      case TelemetryEventNames.classifyTagResult:
        return const <String>[
          'entry_id',
          'tag_name',
          'source',
          'confidence',
          'kept',
        ];
      case TelemetryEventNames.tagEdit:
        return const <String>['action', 'tag_name', 'source', 'entry_id'];
      case TelemetryEventNames.stickerImport:
        return const <String>['source_url', 'license', 'attribute_count', 'result'];
      case TelemetryEventNames.stickerApply:
        return const <String>['sticker_source', 'action', 'tag_merged_count'];
      case TelemetryEventNames.reviewFilter:
        return const <String>['tag_names', 'view_type'];
      case TelemetryEventNames.appOpen:
        return const <String>['ts', 'device_id', 'install_days'];
      default:
        return const <String>[];
    }
  }

  static bool? _kept(Map<String, Object?> payload) =>
      payload['kept'] as bool?;

  static String? _tagName(Map<String, Object?> payload) =>
      payload['tag_name'] as String?;
}

/// 审计输入抽象：便于测试注入，也便于从本地表读取后转换。
class TelemetryEventRowLike {
  const TelemetryEventRowLike({
    required this.eventName,
    required this.payload,
    required this.ts,
  });

  final String eventName;
  final Map<String, Object?> payload;
  final int ts;

  factory TelemetryEventRowLike.fromJson(
    String eventName,
    String payloadJson,
    int ts,
  ) =>
      TelemetryEventRowLike(
        eventName: eventName,
        payload: jsonDecode(payloadJson) as Map<String, Object?>,
        ts: ts,
      );
}
