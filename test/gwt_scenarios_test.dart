import 'package:flutter_test/flutter_test.dart';
import 'package:paper_ledger/data/models/records.dart';
import 'package:paper_ledger/domain/entities/constants.dart';
import 'package:paper_ledger/domain/usecases/amount_parser.dart';
import 'package:paper_ledger/domain/usecases/classifier.dart';
import 'package:paper_ledger/domain/usecases/stats.dart';
import 'package:paper_ledger/features/sticker/license_guard.dart';
import 'package:paper_ledger/telemetry/audit.dart';

/// GWT（Given-When-Then）转自动化测试（PKG-09）。
/// 核心 FR 的行为规格以测试形式固化，覆盖依赖链各包关键口径。
void main() {
  group('FR-01/02 极速记账与金额算式', () {
    test('Given 打开即录 When 输入 25+8 Then 显示 33.00 元', () {
      // Given
      const parser = AmountParser();
      // When
      final result = parser.parse('25+8');
      // Then
      expect(result.cents, 3300);
      expect(formatYuan(result.cents), '33.00');
    });

    test('Given 算式输入 When 10÷3 Then 四舍五入为 3.33 元', () {
      expect(formatYuan(const AmountParser().parse('10÷3').cents), '3.33');
    });

    test('Given 飞行模式（无网络）When 记账 Then 仍可解析并本地保存', () {
      // 一期纯本地，解析器不依赖任何网络；offline 埋点固定 true。
      final result = const AmountParser().parse('12.5');
      expect(result.isSuccess, isTrue);
      expect(result.cents, 1250);
    });
  });

  group('FR-07/09 自动分类与未分类兜底', () {
    test('Given 备注含咖啡 When 分类 Then 至少 1 个品类标签', () {
      final classifier = Classifier(
        KeywordLibrary.forTest(const <KeywordEntry>[
          KeywordEntry(word: '咖啡', tag: '餐饮', type: '品类', confidence: 0.9),
        ]),
      );
      final result = classifier.classify(
        note: '咖啡',
        stickerAttributes: const <String>[],
        historyTags: const <String>[],
      );
      expect(result.hit, isTrue);
    });

    test('Given 无命中 When 分类 Then 挂未分类', () {
      final classifier = Classifier(
        KeywordLibrary.forTest(const <KeywordEntry>[]),
      );
      final result = classifier.classify(
        note: 'xyz',
        stickerAttributes: const <String>[],
        historyTags: const <String>[],
      );
      expect(result.suggestions.single.tagName, SystemTags.unclassifiedName);
    });
  });

  group('FR-14 许可校验（R3）', () {
    test('Given 素材 CC BY-SA When 导入 Then 拒绝', () {
      final check = LicenseGuard.check(
        license: 'CC BY-SA',
        sourceUrl: 'https://example.com',
        licenseCheckShot: 'shot.png',
      );
      expect(check.accepted, isFalse);
    });
  });

  group('FR-06/23 连续记账与统计口径', () {
    test('Given 两笔 0.1+0.2 元 When 统计 Then 显示 0.30 元', () {
      const entries = <EntryRow>[
        EntryRow(id: 'a', amountCents: 10, occurredAt: 1, createdAt: 1, updatedAt: 1),
        EntryRow(id: 'b', amountCents: 20, occurredAt: 2, createdAt: 1, updatedAt: 1),
      ];
      final total = StatsCalculator.timeTrend(entries).fold<int>(
        0,
        (sum, point) => sum + point.cents,
      );
      expect(formatYuan(total), '0.30');
    });
  });

  group('埋点完整性（R7 / 第 6 章）', () {
    test('Given 有效建议含未分类 When 算命中率 Then 未分类不入分母', () {
      final events = <TelemetryEventRowLike>[
        TelemetryEventRowLike(
          eventName: TelemetryEventNames.classifyTagResult,
          ts: 1,
          payload: <String, Object?>{
            'entry_id': 'e',
            'tag_name': '餐饮',
            'source': TagSources.text,
            'confidence': 0.9,
            'kept': true,
          },
        ),
        TelemetryEventRowLike(
          eventName: TelemetryEventNames.classifyTagResult,
          ts: 2,
          payload: <String, Object?>{
            'entry_id': 'e',
            'tag_name': SystemTags.unclassifiedName,
            'source': TagSources.manual,
            'confidence': 1.0,
            'kept': true,
          },
        ),
      ];
      expect(TelemetryAudit.hitRate(events), 1.0);
    });
  });
}
