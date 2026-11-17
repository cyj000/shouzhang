import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection.dart';
import '../../data/models/records.dart';
import '../../domain/entities/constants.dart';
import '../../telemetry/events.dart';
import '../../telemetry/local_logger.dart';

final reviewControllerProvider =
    NotifierProvider<ReviewController, ReviewState>(ReviewController.new);

@immutable
class ReviewSnapshot {
  const ReviewSnapshot({
    required this.entries,
    required this.tagsByEntry,
    required this.stickerInstances,
  });

  final List<EntryRow> entries;
  final Map<String, List<TagRow>> tagsByEntry;
  final List<StickerInstanceRow> stickerInstances;
}

@immutable
class ReviewState {
  const ReviewState({
    required this.fromMs,
    required this.toMs,
    this.allTags = const <TagRow>[],
    this.selectedTags = const <String>{},
    this.snapshot,
    this.viewType = '时间趋势',
    this.namedViews = const <String, List<String>>{},
  });

  final int fromMs;
  final int toMs;
  final List<TagRow> allTags;
  final Set<String> selectedTags;
  final ReviewSnapshot? snapshot;
  final String viewType;
  final Map<String, List<String>> namedViews;

  ReviewState copyWith({
    int? fromMs,
    int? toMs,
    List<TagRow>? allTags,
    Set<String>? selectedTags,
    ReviewSnapshot? snapshot,
    String? viewType,
    Map<String, List<String>>? namedViews,
  }) =>
      ReviewState(
        fromMs: fromMs ?? this.fromMs,
        toMs: toMs ?? this.toMs,
        allTags: allTags ?? this.allTags,
        selectedTags: selectedTags ?? this.selectedTags,
        snapshot: snapshot ?? this.snapshot,
        viewType: viewType ?? this.viewType,
        namedViews: namedViews ?? this.namedViews,
      );

  /// 标签组合筛选（全部命中）；统计视图与图表共用同一结果（FR-22）。
  List<EntryRow> filteredEntries() {
    final entries = snapshot?.entries ?? const <EntryRow>[];
    if (selectedTags.isEmpty) return entries;
    return entries.where((entry) {
      final names = (snapshot?.tagsByEntry[entry.id] ?? const <TagRow>[])
          .map((tag) => tag.name)
          .toSet();
      return selectedTags.every(names.contains);
    }).toList(growable: false);
  }

  Set<String> filteredEntryIds() =>
      filteredEntries().map((entry) => entry.id).toSet();
}

class ReviewController extends Notifier<ReviewState> {
  static const String _namedViewsKey = 'review_named_views';

  @override
  ReviewState build() {
    final now = DateTime.now();
    return ReviewState(
      fromMs: now.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
      toMs: now.millisecondsSinceEpoch,
    );
  }

  Future<void> initialize() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final raw = prefs.getString(_namedViewsKey);
    final views = <String, List<String>>{};
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        views[key] = (value as List<dynamic>).cast<String>();
      });
    }
    state = state.copyWith(namedViews: views);
    await load();
  }

  Future<void> load() async {
    final repos = await ref.read(appRepositoriesProvider.future);
    final entries = await repos.entries.activeInRange(state.fromMs, state.toMs);
    final tagsByEntry = <String, List<TagRow>>{};
    final instances = <StickerInstanceRow>[];
    for (final entry in entries) {
      tagsByEntry[entry.id] = await repos.tags.tagsForEntry(entry.id);
      instances.addAll(await repos.stickers.instancesForEntry(entry.id));
    }
    final allTags = await repos.tags.allTags();
    state = state.copyWith(
      allTags: allTags,
      snapshot: ReviewSnapshot(
        entries: entries,
        tagsByEntry: tagsByEntry,
        stickerInstances: instances,
      ),
    );
  }

  Future<void> toggleTag(String tagName) async {
    final selected = <String>{...state.selectedTags};
    if (!selected.remove(tagName)) selected.add(tagName);
    state = state.copyWith(selectedTags: selected);
    await _trackFilter();
  }

  Future<void> setViewType(String viewType) async {
    state = state.copyWith(viewType: viewType);
    await _trackFilter();
  }

  Future<void> clearFilters() async {
    state = state.copyWith(selectedTags: const <String>{});
    await _trackFilter();
  }

  Future<void> saveNamedView(String name) async {
    if (name.trim().isEmpty) return;
    final views = <String, List<String>>{
      ...state.namedViews,
      name.trim(): state.selectedTags.toList(),
    };
    state = state.copyWith(namedViews: views);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_namedViewsKey, jsonEncode(views));
  }

  Future<void> deleteNamedView(String name) async {
    final views = <String, List<String>>{...state.namedViews}..remove(name);
    state = state.copyWith(namedViews: views);
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_namedViewsKey, jsonEncode(views));
  }

  Future<void> applyNamedView(String name) async {
    final tags = state.namedViews[name];
    if (tags == null) return;
    state = state.copyWith(selectedTags: tags.toSet());
    await _trackFilter();
  }

  Future<void> _trackFilter() async {
    await ref.read(localTelemetryProvider).track(
          TelemetryEventNames.reviewFilter,
          TelemetryEvents.reviewFilter(
            tagNames: state.selectedTags.toList(),
            viewType: state.viewType,
          ),
        );
  }

  Future<void> trackAppOpen(String deviceId) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final installDays = prefs.getInt('install_days') ?? 0;
    await ref.read(localTelemetryProvider).track(
          TelemetryEventNames.appOpen,
          TelemetryEvents.appOpen(
            ts: DateTime.now().millisecondsSinceEpoch,
            deviceId: deviceId,
            installDays: installDays,
          ),
        );
  }
}
