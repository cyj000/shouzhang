import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entities/constants.dart';

class TagSuggestion {
  const TagSuggestion({
    required this.tagName,
    required this.source,
    required this.confidence,
  });

  final String tagName;
  final String source;
  final double confidence;
}

class ClassificationResult {
  const ClassificationResult(this.suggestions);

  final List<TagSuggestion> suggestions;

  /// 有效命中：存在非「未分类」建议（命中率分母口径，第 6 章）。
  bool get hit =>
      suggestions.any((s) => s.tagName != SystemTags.unclassifiedName);
}

class KeywordEntry {
  const KeywordEntry({
    required this.word,
    required this.tag,
    required this.type,
    required this.confidence,
  });

  factory KeywordEntry.fromJson(Map<String, dynamic> json) => KeywordEntry(
        word: json['word'] as String,
        tag: json['tag'] as String,
        type: json['type'] as String? ?? '品类',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      );

  final String word;
  final String tag;
  final String type;
  final double confidence;
}

class KeywordLibrary {
  KeywordLibrary._(this.keywords);

  /// 测试注入用：避免单测依赖 rootBundle。
  factory KeywordLibrary.forTest(List<KeywordEntry> entries) =>
      KeywordLibrary._(entries);

  final List<KeywordEntry> keywords;

  static Future<KeywordLibrary> load() async {
    final raw = await rootBundle.loadString(
      'lib/data/local/assets/keywords.json',
    );
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = decoded['keywords'] as List<dynamic>;
    return KeywordLibrary._(
      list
          .map((e) => KeywordEntry.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

/// FR-08 纠错学习：删标签记负反馈，新增词进候选（本地 SharedPreferences）。
class UserKeywordStore {
  UserKeywordStore(this._prefs);

  static const String _wordsKey = 'classifier_user_words';
  static const String _demotedKey = 'classifier_demoted_tags';
  final SharedPreferences _prefs;

  Map<String, String> loadWords() {
    final raw = _prefs.getString(_wordsKey);
    if (raw == null || raw.isEmpty) return <String, String>{};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as String));
  }

  Set<String> loadDemoted() =>
      (_prefs.getStringList(_demotedKey) ?? <String>{}).toSet();

  Future<void> learn(String word, String tag) async {
    final words = loadWords()..[word] = tag;
    await _prefs.setString(_wordsKey, jsonEncode(words));
  }

  Future<void> demote(String tag) async {
    final demoted = loadDemoted()..add(tag);
    await _prefs.setStringList(_demotedKey, demoted.toList());
  }
}

/// FR-07 自动分类：备注语义 + 贴纸属性 + 历史习惯 → 多标签；无命中挂未分类。
class Classifier {
  const Classifier(
    this._library, {
    Map<String, String> userWords = const <String, String>{},
    Set<String> demoted = const <String>{},
  })  : _userWords = userWords,
        _demoted = demoted;

  final KeywordLibrary _library;
  final Map<String, String> _userWords;
  final Set<String> _demoted;

  ClassificationResult classify({
    required String note,
    required List<String> stickerAttributes,
    required List<String> historyTags,
  }) {
    final suggestions = <TagSuggestion>[];
    final seen = <String>{};

    void add(String tag, String source, double confidence) {
      if (tag.isEmpty || seen.contains(tag) || _demoted.contains(tag)) return;
      seen.add(tag);
      suggestions.add(
        TagSuggestion(
          tagName: tag,
          source: source,
          confidence: confidence.clamp(0.0, 1.0),
        ),
      );
    }

    for (final keyword in _library.keywords) {
      if (note.contains(keyword.word)) {
        add(keyword.tag, TagSources.text, keyword.confidence);
      }
    }
    _userWords.forEach((word, tag) {
      if (note.contains(word)) add(tag, TagSources.text, 0.95);
    });
    for (final attribute in stickerAttributes) {
      add(attribute, TagSources.sticker, 0.85);
    }
    for (final tag in historyTags) {
      add(tag, TagSources.history, 0.70);
    }

    if (suggestions.isEmpty) {
      suggestions.add(
        const TagSuggestion(
          tagName: SystemTags.unclassifiedName,
          source: TagSources.manual,
          confidence: 1.0,
        ),
      );
    }
    return ClassificationResult(suggestions);
  }
}
