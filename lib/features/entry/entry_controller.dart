import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/di/injection.dart';
import '../../data/models/records.dart';
import '../../domain/entities/constants.dart';
import '../../domain/usecases/amount_parser.dart';
import '../../domain/usecases/classifier.dart';
import '../../telemetry/events.dart';
import '../../telemetry/local_logger.dart';

final entryControllerProvider =
    NotifierProvider<EntryController, EntryFormState>(EntryController.new);

@immutable
class EntryFormState {
  const EntryFormState({
    this.expression = '',
    this.type = EntryTypes.expense,
    this.note = '',
    this.paymentMethod,
    this.suggestions = const <TagSuggestion>[],
    this.selectedTagNames = const <String>{},
    this.error,
    this.entryIndex = 0,
    this.lastSaveMs,
    this.sessionStartMs,
    this.lastSavedEntryId,
    this.isSaving = false,
  });

  final String expression;
  final String type;
  final String note;
  final String? paymentMethod;
  final List<TagSuggestion> suggestions;
  final Set<String> selectedTagNames;
  final String? error;
  final int entryIndex;
  final int? lastSaveMs;
  final int? sessionStartMs;
  final String? lastSavedEntryId;

  /// BUGFIX: 保存中标志，防止连点重复写库（第 3.3 节根因1）。
  final bool isSaving;

  EntryFormState copyWith({
    String? expression,
    String? type,
    String? note,
    String? paymentMethod,
    List<TagSuggestion>? suggestions,
    Set<String>? selectedTagNames,
    String? error,
    bool clearError = false,
    int? entryIndex,
    int? lastSaveMs,
    int? sessionStartMs,
    String? lastSavedEntryId,
    bool? isSaving,
  }) =>
      EntryFormState(
        expression: expression ?? this.expression,
        type: type ?? this.type,
        note: note ?? this.note,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        suggestions: suggestions ?? this.suggestions,
        selectedTagNames: selectedTagNames ?? this.selectedTagNames,
        error: clearError ? null : error ?? this.error,
        entryIndex: entryIndex ?? this.entryIndex,
        lastSaveMs: lastSaveMs ?? this.lastSaveMs,
        sessionStartMs: sessionStartMs ?? this.sessionStartMs,
        lastSavedEntryId: lastSavedEntryId ?? this.lastSavedEntryId,
        isSaving: isSaving ?? this.isSaving,
      );

  int? previewCents() {
    final result = const AmountParser().parse(expression);
    return result.isSuccess ? result.cents : null;
  }
}

class EntryController extends Notifier<EntryFormState> {
  static const String _lastPaymentKey = 'last_payment_method';
  bool _initialized = false;

  @override
  EntryFormState build() => const EntryFormState();

  /// FR-01 / DQ-02：冷启动进入记账页，弹系统键盘并打 record_start。
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await ref.read(sharedPreferencesProvider.future);
    final now = DateTime.now().millisecondsSinceEpoch;
    state = state.copyWith(
      paymentMethod: prefs.getString(_lastPaymentKey) ?? '现金',
      sessionStartMs: now,
    );

    final repos = await ref.read(appRepositoriesProvider.future);
    await ref.read(localTelemetryProvider).track(
          TelemetryEventNames.recordStart,
          TelemetryEvents.recordStart(now, repos.oplog.deviceId),
        );
  }

  void updateExpression(String value) =>
      state = state.copyWith(expression: value, clearError: true);

  void appendToken(String token) =>
      updateExpression('${state.expression}$token');

  void backspace() {
    final value = state.expression;
    if (value.isNotEmpty) {
      updateExpression(value.substring(0, value.length - 1));
    }
  }

  void clearExpression() => updateExpression('');

  void toggleType() => state = state.copyWith(
        type: state.type == EntryTypes.expense
            ? EntryTypes.income
            : EntryTypes.expense,
      );

  void setPaymentMethod(String method) =>
      state = state.copyWith(paymentMethod: method);

  Future<void> updateNote(String value) async {
    state = state.copyWith(note: value);
    await reclassify();
  }

  Future<void> reclassify() async {
    final classifier = await ref.read(classifierProvider.future);
    final result = classifier.classify(
      note: state.note,
      // PKG-05 接入贴纸属性；PKG-04 一期历史习惯词库为空。
      stickerAttributes: const <String>[],
      historyTags: const <String>[],
    );

    final retained = result.suggestions
        .where((s) => state.selectedTagNames.contains(s.tagName))
        .map((s) => s.tagName)
        .toSet();
    state = state.copyWith(
      suggestions: result.suggestions,
      selectedTagNames: retained,
    );
  }

  /// FR-08 / 第 6 章：用户增删改标签，写 tag_edit 埋点。
  Future<void> toggleTag(TagSuggestion suggestion) async {
    final selected = <String>{...state.selectedTagNames};
    final isAdding = !selected.contains(suggestion.tagName);
    if (isAdding) {
      selected.add(suggestion.tagName);
    } else {
      selected.remove(suggestion.tagName);
    }
    state = state.copyWith(selectedTagNames: selected);

    await ref.read(localTelemetryProvider).track(
          TelemetryEventNames.tagEdit,
          TelemetryEvents.tagEdit(
            action: isAdding ? 'add' : 'delete',
            tagName: suggestion.tagName,
            source: suggestion.source,
            entryId: state.entryIndex.toString(),
          ),
        );

    // 删标签记负反馈，新增词进候选（FR-08）。
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final store = UserKeywordStore(prefs);
    if (!isAdding) {
      await store.demote(suggestion.tagName);
      ref.invalidate(classifierProvider);
    }
  }

  /// FR-06：先落盘后反馈；失败保留表单；停留记账页连续录入。
  /// BUGFIX：加事务 + 异常捕获 + 防连点锁，修复"数据保存不成功"。
  Future<bool> save() async {
    // 防连点：正在保存时直接拒绝第二次点击（第 3.3 节根因1）。
    if (state.isSaving) return false;

    final parsed = const AmountParser().parse(state.expression);
    if (!parsed.isSuccess) {
      state = state.copyWith(error: _errorText(parsed.status));
      return false;
    }

    // 进入保存态：锁按钮 + 清旧错误。
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final repos = await ref.read(appRepositoriesProvider.future);
      final telemetry = ref.read(localTelemetryProvider);
      final entryId = const Uuid().v4();

      final entry = EntryRow(
        id: entryId,
        type: state.type,
        amountCents: parsed.cents,
        note: state.note.trim().isEmpty ? null : state.note.trim(),
        occurredAt: now,
        paymentMethod: state.paymentMethod,
        createdAt: now,
        updatedAt: now,
      );

      // 一次保存的全部写操作放进同一事务：任何一步失败整体回滚，
      // 杜绝"账目写了但标签/埋点没写"的半截数据（第 3.3 节根因3）。
      await repos.db.transaction(() async {
        await repos.entries.save(entry);

        // 分类建议落库 + 明细埋点（kept 以保存时刻最终状态为准；删后加回仍算保留）。
        var keptCount = 0;
        for (final suggestion in state.suggestions) {
          final isUnclassified =
              suggestion.tagName == SystemTags.unclassifiedName;
          final kept = state.selectedTagNames.contains(suggestion.tagName) ||
              (isUnclassified && state.suggestions.length == 1);
          if (kept) {
            final tagId = await repos.tags.ensureTag(
              suggestion.tagName,
              type: suggestion.source == TagSources.text ? '品类' : null,
            );
            await repos.tags.addTagToEntry(
              EntryTagRow(
                entryId: entryId,
                tagId: tagId,
                source: suggestion.source,
                confidence: suggestion.confidence,
              ),
            );
            keptCount++;
          }
          await telemetry.track(
            TelemetryEventNames.classifyTagResult,
            TelemetryEvents.classifyTagResult(
              entryId: entryId,
              tagName: suggestion.tagName,
              source: suggestion.source,
              confidence: suggestion.confidence,
              kept: kept,
            ),
          );
        }

        final isContinuous = state.entryIndex > 0;
        final durationMs =
            now - (state.lastSaveMs ?? state.sessionStartMs ?? now);
        final hit = state.suggestions.any(
          (s) => s.tagName != SystemTags.unclassifiedName,
        );

        await telemetry.track(
          TelemetryEventNames.recordSave,
          TelemetryEvents.recordSave(
            ts: now,
            amountCents: parsed.cents,
            tagCount: keptCount,
            durationMs: durationMs,
            offline: true, // 一期纯本地，无网络出口（R1）
            entryIndex: state.entryIndex,
            isContinuous: isContinuous,
          ),
        );
        await telemetry.track(
          TelemetryEventNames.classifyResult,
          TelemetryEvents.classifyResult(
            ts: now,
            entryId: entryId,
            tagCount: keptCount,
            hit: hit,
          ),
        );
      }); // end transaction —— 事务提交成功才算落盘

      final prefs = await ref.read(sharedPreferencesProvider.future);
      await prefs.setString(_lastPaymentKey, state.paymentMethod ?? '现金');

      // 先落盘后反馈：事务成功后才清空表单并给连续记账反馈（FR-06）。
      state = state.copyWith(
        expression: '',
        note: '',
        suggestions: const <TagSuggestion>[],
        selectedTagNames: const <String>{},
        entryIndex: state.entryIndex + 1,
        lastSaveMs: now,
        lastSavedEntryId: entryId,
        isSaving: false,
        clearError: true,
      );
      return true;
    } catch (e) {
      // FR-06 异常路径：失败保留表单（expression/note 未清），
      // 给出可读错误提示，解锁按钮允许重试（文档 E1）。
      state = state.copyWith(
        isSaving: false,
        error: '保存失败：${e.toString()}。内容已保留，请重试。',
      );
      return false;
    }
  }

  String _errorText(AmountParseStatus status) {
    switch (status) {
      case AmountParseStatus.empty:
        return '请输入金额';
      case AmountParseStatus.invalidCharacter:
        return '仅支持数字与 + - × ÷';
      case AmountParseStatus.negativeNotAllowed:
        return '不支持负数';
      case AmountParseStatus.parenthesisNotAllowed:
        return '不支持括号';
      case AmountParseStatus.tooManyDecimals:
        return '最多两位小数';
      case AmountParseStatus.missingOperand:
        return '运算符后需要数字';
      case AmountParseStatus.divideByZero:
        return '不能除以 0';
      case AmountParseStatus.overflow:
        return '超出单笔上限 1,000,000 元';
      case AmountParseStatus.negativeResult:
        return '金额不能为负';
      case AmountParseStatus.ok:
        return '';
    }
  }
}
