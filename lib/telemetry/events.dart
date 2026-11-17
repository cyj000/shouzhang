import '../domain/entities/constants.dart';

/// 埋点事件字典（第 6 章，R8）。一期仅本地落库，不上报（R1 / R7）。
abstract final class TelemetryEvents {
  /// record_start: ts, device_id
  static Map<String, Object?> recordStart(int ts, String deviceId) =>
      <String, Object?>{
        'ts': ts,
        'device_id': deviceId,
      };

  /// record_save: ts, amount_range, tag_count, duration_ms, offline,
  /// entry_index, is_continuous
  static Map<String, Object?> recordSave({
    required int ts,
    required int amountCents,
    required int tagCount,
    required int durationMs,
    required bool offline,
    required int entryIndex,
    required bool isContinuous,
  }) =>
      <String, Object?>{
        'ts': ts,
        'amount_range': amountRange(amountCents),
        'tag_count': tagCount,
        'duration_ms': durationMs,
        'offline': offline,
        'entry_index': entryIndex,
        'is_continuous': isContinuous,
      };

  /// classify_result: ts, entry_id, tag_count, hit
  static Map<String, Object?> classifyResult({
    required int ts,
    required String entryId,
    required int tagCount,
    required bool hit,
  }) =>
      <String, Object?>{
        'ts': ts,
        'entry_id': entryId,
        'tag_count': tagCount,
        'hit': hit,
      };

  /// classify_tag_result: entry_id, tag_name, source, confidence, kept
  static Map<String, Object?> classifyTagResult({
    required String entryId,
    required String tagName,
    required String source,
    required double confidence,
    required bool kept,
  }) =>
      <String, Object?>{
        'entry_id': entryId,
        'tag_name': tagName,
        'source': source,
        'confidence': confidence,
        'kept': kept,
      };

  /// tag_edit: action(add/delete), tag_name, source, entry_id
  static Map<String, Object?> tagEdit({
    required String action,
    required String tagName,
    required String source,
    required String entryId,
  }) =>
      <String, Object?>{
        'action': action,
        'tag_name': tagName,
        'source': source,
        'entry_id': entryId,
      };

  /// sticker_import: source_url, license, attribute_count, result
  static Map<String, Object?> stickerImport({
    required String sourceUrl,
    required String license,
    required int attributeCount,
    required String result,
  }) =>
      <String, Object?>{
        'source_url': sourceUrl,
        'license': license,
        'attribute_count': attributeCount,
        'result': result,
      };

  /// sticker_apply: sticker_source, action(apply/undo), tag_merged_count
  static Map<String, Object?> stickerApply({
    required String stickerSource,
    required String action,
    required int tagMergedCount,
  }) =>
      <String, Object?>{
        'sticker_source': stickerSource,
        'action': action,
        'tag_merged_count': tagMergedCount,
      };

  /// review_filter: tag_names, view_type
  static Map<String, Object?> reviewFilter({
    required List<String> tagNames,
    required String viewType,
  }) =>
      <String, Object?>{
        'tag_names': tagNames,
        'view_type': viewType,
      };

  /// app_open: ts, device_id, install_days
  static Map<String, Object?> appOpen({
    required int ts,
    required String deviceId,
    required int installDays,
  }) =>
      <String, Object?>{
        'ts': ts,
        'device_id': deviceId,
        'install_days': installDays,
      };

  /// 金额分档口径（记录 save 事件时用，避免精确金额外泄到本地埋点以外）。
  static String amountRange(int cents) {
    if (cents < 1000) return 'lt_10';
    if (cents < 5000) return '10_50';
    if (cents < 10000) return '50_100';
    if (cents < 50000) return '100_500';
    return 'gte_500';
  }
}
