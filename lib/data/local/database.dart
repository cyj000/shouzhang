import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/open.dart';
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
      // 关键：sqlite3 默认按 libsqlite3.so 加载，但 sqlcipher_flutter_libs 只提供
      // libsqlcipher.so。必须先 override，否则真机报 "libsqlite3.so not found"，
      // 数据库整体打不开 → 所有保存失败（BUG at 2026-11-19）。
      open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
      // Android 6 上 Java 侧预加载更可靠；其他平台内部会直接返回，无副作用。
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'paper_ledger.sqlite'));
      return NativeDatabase(
        file,
        setup: (raw) {
          // PRAGMA key 必须在任何读写前设置；passphrase 为 base64url，无注入风险。
          raw.execute("PRAGMA key = '$passphrase'");
          // 校验确实加载的是 SQLCipher 而非普通 sqlite3：
          // 否则 key 会被静默忽略，库以明文打开（README 强烈建议的防护）。
          final cipherVersion = raw.select('PRAGMA cipher_version;');
          if (cipherVersion.length == 0) {
            throw StateError(
              'SQLCipher 不可用：libsqlcipher.so 未正确加载，拒绝以明文打开数据库',
            );
          }
        },
      );
    });
    return AppDatabase(executor);
  }

  @override
  int get schemaVersion => 1;

  // 本项目采用 Dart-only 表声明 + 全 customSelect/customStatement 访问，
  // 不引入 drift 代码生成；因此不向 allTables 注册 TableInfo，schema 由下方 SQL 显式创建。
  @override
  List<TableInfo<Table, Object?>> get allTables =>
      const <TableInfo<Table, Object?>>[];

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onCreate: (m) async {
          await _createSchema();
          // FR-09：系统保留标签 `未分类`，不可删/改名。
          await customStatement(
            "INSERT OR IGNORE INTO tags (id, name, type, is_system) "
            "VALUES ('${SystemTags.unclassifiedId}', "
            "'${SystemTags.unclassifiedName}', 'system', 1)",
          );
        },
      );

  Future<void> _createSchema() async {
    await customStatement('''
      CREATE TABLE entries (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL DEFAULT 'expense',
        amount_cents INTEGER NOT NULL,
        note TEXT,
        occurred_at INTEGER NOT NULL,
        payment_method TEXT,
        location_lat REAL,
        location_lng REAL,
        location_city TEXT,
        revision INTEGER NOT NULL DEFAULT 0,
        deleted INTEGER NOT NULL DEFAULT 0,
        amount_version INTEGER NOT NULL DEFAULT 0,
        amount_hash INTEGER,
        note_version INTEGER NOT NULL DEFAULT 0,
        note_hash INTEGER,
        tags_version INTEGER NOT NULL DEFAULT 0,
        tags_hash INTEGER,
        stickers_version INTEGER NOT NULL DEFAULT 0,
        stickers_hash INTEGER,
        ink_version INTEGER NOT NULL DEFAULT 0,
        ink_hash INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT,
        is_system INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await customStatement('''
      CREATE TABLE entry_tags (
        entry_id TEXT NOT NULL,
        tag_id TEXT NOT NULL,
        source TEXT NOT NULL,
        confidence REAL NOT NULL DEFAULT 1.0,
        sticker_instance_id TEXT,
        PRIMARY KEY (entry_id, tag_id, source)
      )
    ''');
    await customStatement('''
      CREATE TABLE stickers (
        id TEXT PRIMARY KEY,
        asset_path TEXT NOT NULL,
        attributes_json TEXT NOT NULL,
        source TEXT NOT NULL,
        checksum TEXT NOT NULL,
        removed_at INTEGER,
        remove_reason TEXT
      )
    ''');
    await customStatement('''
      CREATE TABLE sticker_sources (
        sticker_id TEXT PRIMARY KEY,
        source_url TEXT NOT NULL,
        license TEXT NOT NULL,
        obtained_at INTEGER NOT NULL,
        author TEXT,
        license_check_shot TEXT NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE sticker_instances (
        id TEXT PRIMARY KEY,
        entry_id TEXT NOT NULL,
        sticker_id TEXT NOT NULL,
        asset_path_snapshot TEXT NOT NULL,
        attributes_snapshot_json TEXT NOT NULL,
        transform_json TEXT NOT NULL,
        z_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await customStatement('''
      CREATE TABLE ink_layers (
        id TEXT PRIMARY KEY,
        entry_id TEXT NOT NULL,
        strokes_json TEXT NOT NULL
      )
    ''');
    await customStatement('''
      CREATE TABLE oplog (
        op_id TEXT NOT NULL,
        device_id TEXT NOT NULL,
        entity TEXT NOT NULL,
        op_type TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        lamport INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (op_id, device_id)
      )
    ''');
    await customStatement('''
      CREATE TABLE telemetry_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_name TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        ts INTEGER NOT NULL
      )
    ''');

    await customStatement(
      'CREATE INDEX idx_entries_occurred_at ON entries (occurred_at)',
    );
    await customStatement('CREATE INDEX idx_entries_type ON entries (type)');
    await customStatement('CREATE INDEX idx_entries_deleted ON entries (deleted)');
    await customStatement('CREATE UNIQUE INDEX uq_tags_name ON tags (name)');
    await customStatement(
      'CREATE INDEX idx_entry_tags_entry ON entry_tags (entry_id)',
    );
    await customStatement(
      'CREATE INDEX idx_entry_tags_tag ON entry_tags (tag_id)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX uq_stickers_checksum ON stickers (checksum)',
    );
    await customStatement(
      'CREATE INDEX idx_stickers_removed_at ON stickers (removed_at)',
    );
    await customStatement(
      'CREATE INDEX idx_sticker_instances_entry ON sticker_instances (entry_id)',
    );
    await customStatement(
      'CREATE INDEX idx_ink_layers_entry ON ink_layers (entry_id)',
    );
  }
}
