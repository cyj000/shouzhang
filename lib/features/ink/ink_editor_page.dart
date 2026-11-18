import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import 'ink_canvas.dart';

/// 涂鸦编辑页：读取已有增量笔迹并交给 InkCanvas 增量追加（FR-12）。
class InkEditorPage extends ConsumerStatefulWidget {
  const InkEditorPage({required this.entryId, super.key});

  final String entryId;

  @override
  ConsumerState<InkEditorPage> createState() => _InkEditorPageState();
}

class _InkEditorPageState extends ConsumerState<InkEditorPage> {
  late Future<String> _strokes = _loadStrokes();

  Future<String> _loadStrokes() async {
    final repos = await ref.read(appRepositoriesProvider.future);
    final layers = await repos.ink.layersForEntry(widget.entryId);
    return layers.isEmpty ? '[]' : layers.first.strokesJson;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('涂鸦')),
        body: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          child: FutureBuilder<String>(
            future: _strokes,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              return InkCanvas(
                entryId: widget.entryId,
                initialStrokes: snapshot.data ?? '[]',
              );
            },
          ),
        ),
      );
}
