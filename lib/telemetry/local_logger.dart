import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/injection.dart';

/// 本地埋点出口（R7）：所有事件写入本地表，无网络出口。
final localTelemetryProvider = Provider<TelemetrySink>((ref) {
  return TelemetrySink(ref);
});

class TelemetrySink {
  TelemetrySink(this._ref);

  final Ref _ref;

  Future<void> track(String eventName, Map<String, Object?> payload) async {
    final repos = await _ref.read(appRepositoriesProvider.future);
    await repos.telemetry.track(
      eventName,
      payload,
      ts: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
