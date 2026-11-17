import 'package:drift/drift.dart';

/// sticker_sources（开源来源留痕）—— 任务书 §3.5。license 仅 CC0 / CC BY（R3）。
class StickerSources extends Table {
  TextColumn get stickerId => text()();
  TextColumn get sourceUrl => text()();
  TextColumn get license => text()();
  IntColumn get obtainedAt => integer()();
  TextColumn get author => text().nullable()();
  TextColumn get licenseCheckShot => text()();

  @override
  Set<Column> get primaryKey => <Column>{stickerId};
}
