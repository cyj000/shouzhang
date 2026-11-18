import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/records.dart';
import 'sticker_application.dart';
import 'sticker_catalog.dart';

/// FR-10~13：贴纸库浏览/检索/贴附/撤销（预设库随包内置，软删过滤由 DAO 完成）。
class StickerPickerSheet extends ConsumerStatefulWidget {
  const StickerPickerSheet({required this.entryId, super.key});

  final String entryId;

  @override
  ConsumerState<StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends ConsumerState<StickerPickerSheet> {
  String _query = '';
  List<StickerInstanceRow> _instances = const <StickerInstanceRow>[];

  @override
  void initState() {
    super.initState();
    _loadInstances();
  }

  Future<void> _loadInstances() async {
    final repos = await ref.read(appRepositoriesProvider.future);
    final instances = await repos.stickers.instancesForEntry(widget.entryId);
    if (!mounted) return;
    setState(() => _instances = instances);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = StickerCatalog.builtins
        .where(
          (s) =>
              _query.isEmpty ||
              s.label.contains(_query) ||
              s.attributes.any((a) => a.contains(_query)),
        )
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        child: Column(
          children: <Widget>[
            TextField(
              decoration: const InputDecoration(
                hintText: '搜索贴纸 / 属性',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AppTheme.spaceS),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: <Widget>[
                  Wrap(
                    spacing: AppTheme.spaceM,
                    runSpacing: AppTheme.spaceM,
                    children: filtered
                        .map(
                          (sticker) => _StickerTile(
                            sticker: sticker,
                            onTap: () => _apply(sticker),
                          ),
                        )
                        .toList(),
                  ),
                  const Divider(height: AppTheme.spaceXL),
                  Text(
                    '本笔已贴（点按撤销）',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final instance in _instances)
                    ListTile(
                      leading: const Icon(Icons.label_outlined),
                      title: Text(instance.assetPathSnapshot),
                      subtitle: Text(
                        jsonDecode(instance.attributesSnapshotJson).join(' · '),
                      ),
                      onTap: () => _undo(instance),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _apply(BuiltinSticker sticker) async {
    final application = await ref.read(stickerApplicationProvider.future);
    await application.apply(entryId: widget.entryId, sticker: sticker);
    await _loadInstances();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已贴「${sticker.label}」，属性已并入标签')),
      );
    }
  }

  Future<void> _undo(StickerInstanceRow instance) async {
    final application = await ref.read(stickerApplicationProvider.future);
    await application.undo(
      entryId: widget.entryId,
      instanceId: instance.id,
      stickerSource: instance.assetPathSnapshot,
    );
    await _loadInstances();
  }
}

class _StickerTile extends StatelessWidget {
  const _StickerTile({required this.sticker, required this.onTap});

  final BuiltinSticker sticker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 88,
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceM),
                decoration: BoxDecoration(
                  color: sticker.color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: Icon(sticker.icon, size: 36, color: sticker.color),
              ),
              const SizedBox(height: AppTheme.spaceXS),
              Text(sticker.label, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      );
}
