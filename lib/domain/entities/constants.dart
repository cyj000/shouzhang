/// 全局枚举与常量口径（R8：以任务书为准，不自行发明）。
abstract final class EntryTypes {
  static const String expense = 'expense';
  static const String income = 'income';
}

/// 标签来源（§3.3 source 字段）。
abstract final class TagSources {
  static const String text = '文本';
  static const String sticker = '贴纸';
  static const String history = '历史';
  static const String manual = '手动';
}

/// 系统保留标签（FR-09：不可删/改名）。
abstract final class SystemTags {
  static const String unclassifiedId = 'sys_unclassified';
  static const String unclassifiedName = '未分类';
}

/// 金额上限：100,000,000 分（FR-02）。
abstract final class AmountRules {
  static const int maxCents = 100000000;
}

/// 软删 tombstone 保留 90 天（§3.10 / DQ-05）。
abstract final class RetentionRules {
  static const int tombstoneDays = 90;
}

/// 事件名（第 6 章字典，R8）。
abstract final class TelemetryEventNames {
  static const String recordStart = 'record_start';
  static const String recordSave = 'record_save';
  static const String classifyResult = 'classify_result';
  static const String classifyTagResult = 'classify_tag_result';
  static const String tagEdit = 'tag_edit';
  static const String stickerImport = 'sticker_import';
  static const String stickerApply = 'sticker_apply';
  static const String reviewFilter = 'review_filter';
  static const String appOpen = 'app_open';
}
