import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di/injection.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/records.dart';
import 'ink_models.dart';
import 'ink_painter.dart';

/// 涂鸦画布（FR-12）：抬起一笔后增量落库一条指令。
class InkCanvas extends ConsumerStatefulWidget {
  const InkCanvas({
    required this.entryId,
    required this.initialStrokes,
    super.key,
  });

  final String entryId;
  final String initialStrokes;

  @override
  ConsumerState<InkCanvas> createState() => _InkCanvasState();
}

class _InkCanvasState extends ConsumerState<InkCanvas> {
  late InkDocument _document = InkDocument.decode(widget.initialStrokes);
  InkStroke? _active;
  String? _layerId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onPanStart: (details) => setState(() {
              _active = InkStroke(
                points: <Offset>[details.localPosition],
                colorValue: AppTheme.ink.value,
                width: 3.0,
              );
            }),
            onPanUpdate: (details) => setState(() {
              final stroke = _active;
              if (stroke != null) {
                _active = stroke.copyWithPoints(
                  <Offset>[...stroke.points, details.localPosition],
                );
              }
            }),
            onPanEnd: (_) => _finishStroke(),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.paper,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(color: AppTheme.inkSoft),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                child: CustomPaint(
                  painter: InkPainter(
                    strokes: _document.strokes,
                    active: _active,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _document = InkDocument.empty();
                _active = null;
              });
              _persist();
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('清空'),
          ),
        ),
      ],
    );
  }

  void _finishStroke() {
    final stroke = _active;
    if (stroke == null) return;
    setState(() {
      _document = _document.append(stroke);
      _active = null;
    });
    _persist();
  }

  Future<void> _persist() async {
    final repos = await ref.read(appRepositoriesProvider.future);
    _layerId ??= const Uuid().v4();
    await repos.ink.saveInk(
      InkLayerRow(
        id: _layerId!,
        entryId: widget.entryId,
        strokesJson: _document.encode(),
      ),
    );
  }
}
