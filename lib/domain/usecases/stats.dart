import '../../data/models/records.dart';

/// FR-23 统计口径：金额一律分单位整数相加后再格式化，禁浮点（R2）。
/// 五类视图：时间趋势 / 品类排行 / 品牌复购 / 支付方式占比 / 贴纸属性汇总。
/// 无「按地点」维度（一期坐标字段为空）。

class TimePoint {
  const TimePoint(this.label, this.cents);
  final String label;
  final int cents;
}

class RankItem {
  const RankItem(this.label, this.cents, this.count);
  final String label;
  final int cents;
  final int count;
}

abstract final class StatsCalculator {
  static List<TimePoint> timeTrend(List<EntryRow> entries) {
    final buckets = <String, int>{};
    for (final entry in entries) {
      if (entry.type != 'expense') continue;
      final date = DateTime.fromMillisecondsSinceEpoch(entry.occurredAt);
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      buckets[key] = (buckets[key] ?? 0) + entry.amountCents;
    }
    final keys = buckets.keys.toList()..sort();
    return keys.map((key) => TimePoint(key, buckets[key]!)).toList();
  }

  static List<RankItem> byTagType(
    List<EntryRow> entries,
    Map<String, List<TagRow>> tagsByEntry,
    String tagType,
  ) {
    final totals = <String, int>{};
    final counts = <String, int>{};
    for (final entry in entries) {
      if (entry.type != 'expense') continue;
      for (final tag in tagsByEntry[entry.id] ?? const <TagRow>[]) {
        if (tag.type != tagType) continue;
        totals[tag.name] = (totals[tag.name] ?? 0) + entry.amountCents;
        counts[tag.name] = (counts[tag.name] ?? 0) + 1;
      }
    }
    return _rank(totals, counts);
  }

  /// 品牌复购：品牌标签出现次数 >= 2（复购次数口径）。
  static List<RankItem> brandRepeat(
    List<EntryRow> entries,
    Map<String, List<TagRow>> tagsByEntry,
  ) =>
      byTagType(entries, tagsByEntry, '品牌')
          .where((item) => item.count >= 2)
          .toList();

  static List<RankItem> paymentBreakdown(List<EntryRow> entries) {
    final totals = <String, int>{};
    final counts = <String, int>{};
    for (final entry in entries) {
      if (entry.type != 'expense') continue;
      final method = entry.paymentMethod ?? '未记录';
      totals[method] = (totals[method] ?? 0) + entry.amountCents;
      counts[method] = (counts[method] ?? 0) + 1;
    }
    return _rank(totals, counts);
  }

  static List<RankItem> stickerAttributes(
    List<StickerInstanceRow> instances,
    Set<String> entryIds,
  ) {
    final totals = <String, int>{};
    final counts = <String, int>{};
    for (final instance in instances) {
      if (!entryIds.contains(instance.entryId)) continue;
      // 用历史快照属性统计（软删后仍参与，DQ-08）。
      for (final attribute in parseAttributes(instance.attributesSnapshotJson)) {
        totals[attribute] = (totals[attribute] ?? 0) + 1;
        counts[attribute] = (counts[attribute] ?? 0) + 1;
      }
    }
    return _rank(totals, counts);
  }

  static List<String> parseAttributes(String json) {
    if (json.isEmpty || json == '[]') return const <String>[];
    // 属性为字符串数组，简单解析避免引入额外依赖。
    return json
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<RankItem> _rank(
    Map<String, int> totals,
    Map<String, int> counts,
  ) {
    final keys = totals.keys.toList()
      ..sort((a, b) => totals[b]!.compareTo(totals[a]!));
    return keys
        .map((key) => RankItem(key, totals[key]!, counts[key] ?? 0))
        .toList(growable: false);
  }
}
