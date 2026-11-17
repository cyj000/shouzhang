import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/constants.dart';
import '../../domain/usecases/amount_parser.dart';
import '../../telemetry/events.dart';
import '../../telemetry/local_logger.dart';

/// FR-09：未分类账目回顾页聚合批量归类。
class UnclassifiedSheet extends ConsumerStatefulWidget {
  const UnclassifiedSheet({super.key});

  @override
  ConsumerState<UnclassifiedSheet> createState() => _UnclassifiedSheetState();
}

class _UnclassifiedSheetState extends ConsumerState<UnclassifiedSheet> {
  final _tagController = TextEditingController();
  final Set<String> _selected = <String>{};
  late Future<List<String>> _ids;
  Map<String, int> _amounts = <String, int>{};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final repos = await ref.read(appRepositoriesProvider.future);
    final ids = await repos.tags.unclassifiedEntryIds();
    final amounts = <String, int>{};
    for (final id in ids) {
      final entry = await repos.entries.findById(id);
      if (entry != null) amounts[id] = entry.amountCents;
    }
    if (!mounted) return;
    setState(() {
      _ids = Future<List<String>>.value(ids);
      _amounts = amounts;
      _selected.clear();
    });
  }

  Future<void> _apply() async {
    final tagName = _tagController.text.trim();
    if (tagName.isEmpty || _selected.isEmpty) return;

    final repos = await ref.read(appRepositoriesProvider.future);
    final tagId = await repos.tags.ensureTag(tagName);
    for (final entryId in _selected) {
      await repos.tags.addEntryTag(
        EntryTagRow(
          entryId: entryId,
          tagId: tagId,
          source: TagSources.manual,
          confidence: 1.0,
        ),
      );
      await ref.read(localTelemetryProvider).track(
            TelemetryEventNames.tagEdit,
            TelemetryEvents.tagEdit(
              action: 'add',
              tagName: tagName,
              source: TagSources.manual,
              entryId: entryId,
            ),
          );
    }
    _tagController.clear();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        child: Column(
          children: <Widget>[
            Text('未分类账目', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spaceS),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _ids,
                builder: (context, snapshot) {
                  final ids = snapshot.data ?? const <String>[];
                  if (ids.isEmpty) {
                    return const Center(child: Text('没有未分类账目'));
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: ids.length,
                    itemBuilder: (context, index) {
                      final id = ids[index];
                      return CheckboxListTile(
                        title: Text(formatYuan(_amounts[id] ?? 0)),
                        subtitle: Text(id.substring(0, 8)),
                        value: _selected.contains(id),
                        onChanged: (checked) => setState(() {
                          if (checked ?? false) {
                            _selected.add(id);
                          } else {
                            _selected.remove(id);
                          }
                        }),
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: '批量归类到标签',
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceS),
                FilledButton(
                  onPressed: _apply,
                  child: const Text('归类'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
