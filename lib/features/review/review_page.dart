import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/records.dart';
import '../../domain/usecases/amount_parser.dart';
import '../../domain/usecases/stats.dart';
import 'export_service.dart';
import 'review_controller.dart';

/// 多维回顾页（FR-22~24）：标签筛选联动 + 5 类视图 + 命名视图 + CSV/图片导出。
class ReviewPage extends ConsumerStatefulWidget {
  const ReviewPage({super.key});

  @override
  ConsumerState<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends ConsumerState<ReviewPage> {
  static const List<String> _viewTypes = <String>[
    '时间趋势',
    '品类排行',
    '品牌复购',
    '支付方式占比',
    '贴纸属性汇总',
  ];

  final GlobalKey _chartBoundaryKey = GlobalKey();
  final TextEditingController _viewNameController = TextEditingController();
  bool _initialized = false;

  static const ExportService _exporter = ExportService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized) {
        _initialized = true;
        ref.read(reviewControllerProvider.notifier).initialize();
      }
    });
  }

  @override
  void dispose() {
    _viewNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewControllerProvider);
    final notifier = ref.read(reviewControllerProvider.notifier);
    final entries = state.filteredEntries();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppTheme.spaceXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceM,
                AppTheme.spaceL,
                AppTheme.spaceM,
                AppTheme.spaceS,
              ),
              child: Text(
                '多维回顾',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            _buildFilterChips(state, notifier),
            _buildViewSwitch(state, notifier),
            RepaintBoundary(
              key: _chartBoundaryKey,
              child: _buildChart(state),
            ),
            _buildNamedViews(state, notifier),
            _buildExportButtons(entries),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(ReviewState state, ReviewController notifier) {
    final tags = state.allTags
        .where((tag) => !tag.isSystem)
        .toList(growable: false);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM),
      child: Wrap(
        spacing: AppTheme.spaceS,
        children: <Widget>[
          FilterChip(
            label: const Text('全部'),
            selected: state.selectedTags.isEmpty,
            onSelected: (_) => notifier.clearFilters(),
          ),
          for (final tag in tags)
            FilterChip(
              label: Text(tag.name),
              selected: state.selectedTags.contains(tag.name),
              onSelected: (_) => notifier.toggleTag(tag.name),
            ),
        ],
      ),
    );
  }

  Widget _buildViewSwitch(ReviewState state, ReviewController notifier) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM),
        scrollDirection: Axis.horizontal,
        itemCount: _viewTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spaceS),
        itemBuilder: (context, index) {
          final view = _viewTypes[index];
          return ChoiceChip(
            label: Text(view),
            selected: state.viewType == view,
            onSelected: (_) => notifier.setViewType(view),
          );
        },
      ),
    );
  }

  Widget _buildChart(ReviewState state) {
    final entries = state.filteredEntries();
    final snapshot = state.snapshot;
    if (snapshot == null) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.spaceXL),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.spaceXL),
        child: Center(child: Text('这段时间还没有账目')),
      );
    }

    late final List<(String, int, int)> bars;
    switch (state.viewType) {
      case '品类排行':
        bars = StatsCalculator.byTagType(entries, snapshot.tagsByEntry, '品类')
            .map((item) => (item.label, item.cents, item.count))
            .toList();
      case '品牌复购':
        bars = StatsCalculator.brandRepeat(entries, snapshot.tagsByEntry)
            .map((item) => (item.label, item.cents, item.count))
            .toList();
      case '支付方式占比':
        bars = StatsCalculator.paymentBreakdown(entries)
            .map((item) => (item.label, item.cents, item.count))
            .toList();
      case '贴纸属性汇总':
        bars = StatsCalculator.stickerAttributes(
          snapshot.stickerInstances,
          state.filteredEntryIds(),
        ).map((item) => (item.label, item.cents, item.count)).toList();
      case '时间趋势':
      default:
        bars = StatsCalculator.timeTrend(entries)
            .map((point) => (point.label, point.cents, 1))
            .toList();
    }

    if (bars.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.spaceXL),
        child: Center(child: Text('该视图暂无数据')),
      );
    }

    final maxCents = bars.map((bar) => bar.$2).reduce((a, b) => a > b ? a : b);
    final isCountView = state.viewType == '贴纸属性汇总';

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          child: Column(
            children: <Widget>[
              for (final bar in bars)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spaceXS,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(bar.$1),
                          Text(
                            isCountView
                                ? '${bar.$3} 次'
                                : formatYuan(bar.$2),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceXS),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final ratio = maxCents == 0
                              ? 0.0
                              : bar.$2 / maxCents;
                          return Container(
                            height: 12,
                            width: constraints.maxWidth * ratio,
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusS),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNamedViews(ReviewState state, ReviewController notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: AppTheme.spaceM),
          Text('自定义视图', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppTheme.spaceS),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _viewNameController,
                  decoration: const InputDecoration(hintText: '视图名称'),
                ),
              ),
              const SizedBox(width: AppTheme.spaceS),
              FilledButton(
                onPressed: () {
                  notifier.saveNamedView(_viewNameController.text);
                  _viewNameController.clear();
                },
                child: const Text('保存'),
              ),
            ],
          ),
          Wrap(
            spacing: AppTheme.spaceS,
            children: state.namedViews.keys.map((name) {
              return InputChip(
                label: Text(name),
                onPressed: () => notifier.applyNamedView(name),
                onDeleted: () => notifier.deleteNamedView(name),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButtons(List<EntryRow> entries) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceM,
        vertical: AppTheme.spaceM,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final path = await _exporter.exportCsv(entries);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已导出 ${exportDisplayName(path)}'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('导出 CSV'),
            ),
          ),
          const SizedBox(width: AppTheme.spaceS),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final path = await _exporter.exportImage(_chartBoundaryKey);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        path == null
                            ? '图片导出失败'
                            : '已导出 ${exportDisplayName(path)}',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.image_outlined),
              label: const Text('导出图片'),
            ),
          ),
        ],
      ),
    );
  }
}
