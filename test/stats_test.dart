import 'package:flutter_test/flutter_test.dart';
import 'package:paper_ledger/data/models/records.dart';
import 'package:paper_ledger/domain/usecases/amount_parser.dart';
import 'package:paper_ledger/domain/usecases/stats.dart';

void main() {
  test('0.1 + 0.2 元分单位相加后显示 0.30', () {
    final entries = <EntryRow>[
      const EntryRow(id: 'a', amountCents: 10, occurredAt: 1, createdAt: 1, updatedAt: 1),
      const EntryRow(id: 'b', amountCents: 20, occurredAt: 2, createdAt: 1, updatedAt: 1),
    ];
    final trend = StatsCalculator.timeTrend(entries);
    final total = trend.fold<int>(0, (sum, point) => sum + point.cents);
    expect(total, 30);
    expect(formatYuan(total), '0.30');
  });

  test('五类视图口径：品类/品牌/支付/贴纸属性按整数汇总', () {
    final entries = <EntryRow>[
      const EntryRow(
        id: 'a',
        amountCents: 1000,
        occurredAt: 1,
        createdAt: 1,
        updatedAt: 1,
        paymentMethod: '微信',
      ),
      const EntryRow(
        id: 'b',
        amountCents: 500,
        occurredAt: 2,
        createdAt: 1,
        updatedAt: 1,
        paymentMethod: '微信',
      ),
    ];
    final tags = <String, List<TagRow>>{
      'a': const <TagRow>[
        TagRow(id: 't1', name: '餐饮', type: '品类'),
        TagRow(id: 't2', name: '星巴克', type: '品牌'),
      ],
      'b': const <TagRow>[
        TagRow(id: 't1', name: '餐饮', type: '品类'),
        TagRow(id: 't2', name: '星巴克', type: '品牌'),
      ],
    };

    final category = StatsCalculator.byTagType(entries, tags, '品类');
    expect(category.single.cents, 1500);

    final brands = StatsCalculator.brandRepeat(entries, tags);
    expect(brands.single.label, '星巴克');
    expect(brands.single.count, 2);

    final payments = StatsCalculator.paymentBreakdown(entries);
    expect(payments.single.cents, 1500);

    final stickers = StatsCalculator.stickerAttributes(
      const <StickerInstanceRow>[
        StickerInstanceRow(
          id: 'i1',
          entryId: 'a',
          stickerId: 's1',
          assetPathSnapshot: 'builtin://coffee',
          attributesSnapshotJson: '["餐饮","咖啡"]',
          transformJson: '{}',
          zOrder: 0,
        ),
      ],
      <String>{'a', 'b'},
    );
    expect(stickers.map((e) => e.label), containsAll(<String>['餐饮', '咖啡']));
  });
}
