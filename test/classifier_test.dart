import 'package:flutter_test/flutter_test.dart';
import 'package:paper_ledger/domain/entities/constants.dart';
import 'package:paper_ledger/domain/usecases/classifier.dart';

KeywordLibrary _libraryWith(List<KeywordEntry> entries) =>
    KeywordLibrary.forTest(entries);

void main() {
  test('备注命中：至少一个品类标签', () {
    final classifier = Classifier(
      _libraryWith(const <KeywordEntry>[
        KeywordEntry(
          word: '咖啡',
          tag: '餐饮',
          type: '品类',
          confidence: 0.9,
        ),
      ]),
    );
    final result = classifier.classify(
      note: '星巴克 咖啡',
      stickerAttributes: const <String>[],
      historyTags: const <String>[],
    );
    expect(result.hit, isTrue);
    expect(result.suggestions.first.tagName, '餐饮');
    expect(result.suggestions.first.source, TagSources.text);
  });

  test('无命中：挂未分类且不计入命中率分母', () {
    final classifier = Classifier(_libraryWith(const <KeywordEntry>[]));
    final result = classifier.classify(
      note: '随便记一笔',
      stickerAttributes: const <String>[],
      historyTags: const <String>[],
    );
    expect(result.hit, isFalse);
    expect(result.suggestions.single.tagName, SystemTags.unclassifiedName);
  });

  test('贴纸属性与历史习惯并入，来源正确', () {
    final classifier = Classifier(
      _libraryWith(const <KeywordEntry>[]),
      userWords: const <String, String>{'拿铁': '咖啡'},
    );
    final result = classifier.classify(
      note: '拿铁',
      stickerAttributes: const <String>['品牌·星巴克'],
      historyTags: const <String>['餐饮'],
    );
    final names = result.suggestions.map((s) => s.tagName).toList();
    expect(names, contains('咖啡'));
    expect(names, contains('品牌·星巴克'));
    expect(names, contains('餐饮'));
    expect(
      result.suggestions
          .firstWhere((s) => s.tagName == '品牌·星巴克')
          .source,
      TagSources.sticker,
    );
  });

  test('负反馈降权的标签不再建议', () {
    final classifier = Classifier(
      _libraryWith(const <KeywordEntry>[
        KeywordEntry(
          word: '咖啡',
          tag: '餐饮',
          type: '品类',
          confidence: 0.9,
        ),
      ]),
      demoted: const <String>{'餐饮'},
    );
    final result = classifier.classify(
      note: '咖啡',
      stickerAttributes: const <String>[],
      historyTags: const <String>[],
    );
    expect(result.hit, isFalse);
  });
}
