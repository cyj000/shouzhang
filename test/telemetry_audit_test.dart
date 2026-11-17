import 'package:flutter_test/flutter_test.dart';
import 'package:paper_ledger/domain/entities/constants.dart';
import 'package:paper_ledger/telemetry/audit.dart';

TelemetryEventRowLike _tagResult(String tag, bool kept) =>
    TelemetryEventRowLike(
      eventName: TelemetryEventNames.classifyTagResult,
      ts: 1,
      payload: <String, Object?>{
        'entry_id': 'e1',
        'tag_name': tag,
        'source': TagSources.text,
        'confidence': 0.9,
        'kept': kept,
      },
    );

void main() {
  test('命中率：kept 条数 ÷ 有效建议（排除未分类）', () {
    final events = <TelemetryEventRowLike>[
      _tagResult('餐饮', true),
      _tagResult('星巴克', false),
      _tagResult('交通', true),
      _tagResult(SystemTags.unclassifiedName, true), // 不计入分母
    ];
    final rate = TelemetryAudit.hitRate(events);
    expect(rate, closeTo(2 / 3, 0.0001));
  });

  test('无有效建议时命中率为 0', () {
    expect(
      TelemetryAudit.hitRate(<TelemetryEventRowLike>[
        _tagResult(SystemTags.unclassifiedName, true),
      ]),
      0.0,
    );
  });

  test('完整率：必填字段齐全的事件占比', () {
    final events = <TelemetryEventRowLike>[
      TelemetryEventRowLike(
        eventName: TelemetryEventNames.recordSave,
        ts: 1,
        payload: <String, Object?>{
          'ts': 1,
          'amount_range': '10_50',
          'tag_count': 1,
          'duration_ms': 300,
          'offline': true,
          'entry_index': 0,
          'is_continuous': false,
        },
      ),
      TelemetryEventRowLike(
        eventName: TelemetryEventNames.recordSave,
        ts: 2,
        payload: <String, Object?>{'ts': 2}, // 缺字段
      ),
    ];
    expect(TelemetryAudit.completeness(events), 0.5);
  });

  test('7 日回访率：仅统计第 7 日回访设备', () {
    final day0 = DateTime(2026, 1, 1).millisecondsSinceEpoch;
    final day7 = day0 + 7 * 24 * 60 * 60 * 1000;
    final events = <TelemetryEventRowLike>[
      TelemetryEventRowLike(
        eventName: TelemetryEventNames.appOpen,
        ts: day0,
        payload: <String, Object?>{
          'ts': day0,
          'device_id': 'A',
          'install_days': 0,
        },
      ),
      TelemetryEventRowLike(
        eventName: TelemetryEventNames.appOpen,
        ts: day7,
        payload: <String, Object?>{
          'ts': day7,
          'device_id': 'A',
          'install_days': 7,
        },
      ),
      TelemetryEventRowLike(
        eventName: TelemetryEventNames.appOpen,
        ts: day0,
        payload: <String, Object?>{
          'ts': day0,
          'device_id': 'B',
          'install_days': 0,
        },
      ),
    ];
    expect(TelemetryAudit.day7ReturnRate(events), 0.5);
  });
}
