import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

import '../../domain/entities/constants.dart';
import 'tables/entries.dart';
import 'tables/entry_tags.dart';
import 'tables/ink_layers.dart';
import 'tables/oplog.dart';
import 'tables/sticker_instances.dart';
import 'tables/sticker_sources.dart';
import 'tables/stickers.dart';
import 'tables/tags.dart';
import 'tables/telemetry_events.dart';

export 'tables/entries.dart';
export 'tables/entry_tags.dart';
export 'tables/ink_layers.dart';
export 'tables/oplog.dart';
export 'tables/sticker_instances.dart';
export 'tables/sticker_sources.dart';
export 'tables/stickers.dart';
export 'tables/tags.dart';
export 'tables/telemetry_events.dart';

/// Drift 数据库：SQLCipher AES-256 加密打开（FR-25 / DQ-01 / R1）。
class AppDatabase extends GeneratedDatabase {
  AppDatabase(QueryExecutor executor) : super(executor);

  /// 测试用内存库：不加密，仅用于 GWT/单元测试。
  factory AppDatabase.memory({bool logStatements = false}) =>
      AppDatabase(NativeDatabase.memory(logStatements: logStatements));

  /// 生产打开：passphrase 由 KeystoreService 解出，不明文落文件。
  static AppDatabase openEncrypted(String passphrase) {
    final executor = LazyDatabase(() async {
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'paper_ledger.sqlite'));
      return NativeDatabase(
        file,
        setup: (raw) {
          // PRAGMA key 必须在任何读写前设置；passphrase 为 base64url，无注入风险。
          raw.execute("PRAGMA key = '$passphrase'");
        },
      );
    });
    return AppDatabase(executor);
  }

  @override
  int get schemaVersion => 1;

  final Entries entries = Entries();
  final Tags tags = Tags();
  final EntryTags entryTags = EntryTags();
  final Stickers stickers = Stickers();
  final StickerSources stickerSources = StickerSources();
  final StickerInstances stickerInstances = StickerInstances();
  final InkLayers inkLayers = InkLayers();
  final Oplog oplog = Oplog();
  final TelemetryEvents telemetryEvents = TelemetryEvents();

  @override
  List<TableInfo<Table, Object?>> get allTables =>
      <TableInfo<Table, Object?>>[
        entries,
        tags,
        entryTags,
        stickers,
        stickerSources,
        stickerInstances,
        inkLayers,
        oplog,
        telemetryEvents,
      ];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onCreate: (m) async {
          await m.createAll();
          // FR-09：系统保留标签 `未分类`，不可删/改名。
          await customStatement(
            "INSERT OR IGNORE INTO tags (id, name, type, is_system) "
            "VALUES ('${SystemTags.unclassifiedId}', "
            "'${SystemTags.unclassifiedName}', 'system', 1)",
          );
        },
      );
}
