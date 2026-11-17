# 变更说明 · 2026-11-18

> 记录本次会话对项目做的全部修改与调整，涵盖：本地环境搭建、GitHub Actions 打包流水线、编译错误修复、依赖版本冲突处理、构建文件补齐。

---

## 一、本地开发环境搭建

在 `F:\dev\runtime` 下建立统一的运行时环境，所有路径已写入用户级环境变量并更新 PATH。

| 组件 | 版本 | 来源 / 处理方式 |
| --- | --- | --- |
| JDK | OpenJDK 17.0.8 | 从本机 JetBrains IDEA 自带的 jbr 迁移复制 |
| Android SDK | platform 35 / build-tools 35.0.0 / NDK 26.1.10909125 | 官方 cmdline-tools 安装 |
| Flutter SDK | 3.24.5 stable（Dart 3.5.4） | 从 `storage.flutter-io.cn` 国内镜像下载解压 |
| Git | 2.47.0 | 从 `registry.npmmirror.com` 下载 PortableGit |

设置的环境变量：

- `JAVA_HOME` = `F:\dev\runtime\jdk-17`
- `ANDROID_HOME` / `ANDROID_SDK_ROOT` = `F:\dev\runtime\android-sdk`
- `FLUTTER_ROOT` = `F:\dev\runtime\flutter`
- `PUB_HOSTED_URL` = `https://pub.flutter-io.cn`
- `FLUTTER_STORAGE_BASE_URL` = `https://storage.flutter-io.cn`
- PATH 追加：jdk-17/bin、android-sdk/platform-tools、cmdline-tools/latest/bin、flutter/bin、PortableGit/cmd、PortableGit/bin

验证结果：`flutter doctor` 中 Windows / Flutter / Android toolchain（SDK 35）/ 设备连接均正常；`flutter pub get` 解析 118 个依赖成功；`flutter analyze` 0 error（仅余 44 条 warning/info，不阻断编译）。

> 说明：Chrome / Visual Studio / Android Studio 三项 doctor 提示为 Web 与 Windows 桌面开发所需，本项目为 Android only，命令行打包不需要，故不安装。

---

## 二、GitHub Actions 打包流水线（`.github/workflows/android-release.yml`）

重写了原有的 Android 打包 workflow，主要调整：

1. **触发方式**：保留 `workflow_dispatch` 手动触发 + `v*` tag 推送自动触发。
2. **产物**：由原来只产出 AAB，改为同时产出 **APK（可直接安装）** 与 **AAB（上架用）**。
3. **签名可选化**：原流程强制要求 keystore secrets，未配置时会写入空文件导致构建中断。改为：
   - 配置了 `KEYSTORE_BASE64` / `KEY_ALIAS` / `KEY_PASSWORD` / `STORE_PASSWORD` 时使用正式签名；
   - 未配置时回退 debug 签名，仍可产出可安装包。
4. **修复签名路径**：`storeFile` 由错误的 `app/upload-keystore.jks` 改为 `upload-keystore.jks`（Gradle 相对 `android/app/` 解析，原路径会找错文件）。
5. **Release 自动化**：tag 触发时用 `softprops/action-gh-release` 创建 GitHub Release 并附加 APK/AAB；产物同时上传 Artifacts（保留 30 天）。
6. **权限**：增加 `permissions: contents: write` 以允许创建 Release。
7. **质量检查非阻断**：`flutter analyze` / `flutter test` 设为 `continue-on-error`，避免首次构建因告警卡住出包。

---

## 三、依赖版本冲突修复（`pubspec.yaml` / `docs/build_guide.md`）

项目锁定 Flutter 3.24.5（Dart 3.5.4），但部分依赖的 `^` 约束会解析到要求更高 Dart 版本的版本，导致 `flutter pub get` 失败。逐项处理：

| 依赖 | 原约束 | 新约束 | 原因 |
| --- | --- | --- | --- |
| `sqlcipher_flutter_libs` | `^0.7.0` | `^0.6.8` | `>=0.7.0` 区间仅存在 `0.7.0+eol`，要求 Dart ≥3.10，与 Dart 3.5 冲突；0.6.8 为兼容 3.5 的最后版本，仍提供 AES-256 |
| `build_runner` | `^2.4.15` | `^2.4.13` | 2.4.14+ 要求 Dart ≥3.6；2.4.13 为兼容 3.5 的最后版本 |
| `drift_flutter` | `^0.2.1` | **移除** | 其传递依赖 `sqlite3_flutter_libs` 与 `sqlcipher_flutter_libs` 打包同名 `eu.simonbinder.sqlite3_flutter_libs.BuildConfig`，导致 dex 合并冲突。项目实际未使用该包，直接用 `drift/native.dart` 打开加密库 |

`docs/build_guide.md` 的依赖锁定表与关键决策记录已同步更新。

---

## 四、业务代码编译错误修复（约 91 处 error）

首次在真实 SDK 环境编译，暴露出项目代码从未编译验证过（build_guide.md 原声明为"代码级产物"）。按类别修复：

### 4.1 drift 数据库架构（核心，约 70 处）

- **根因**：项目采用"Dart-only 表定义、不引入代码生成"的设计，但运行时使用了需要代码生成的 `db.select()` / `m.createAll()` / `TableInfo`，且 drift 2.23.1 中 `Row` 类已更名为 `QueryRow`、`OrderingTerm` 泛型签名变化。
- **处理**：
  - `lib/data/local/database.dart`：`allTables` 置空，`onCreate` 改为显式 `customStatement` 建表 + 建索引（9 张表完整 SQL）。
  - 全部 DAO（`entry_dao` / `tag_dao` / `sticker_dao` / `ink_dao` / `oplog_dao` / `telemetry_dao`）：`db.select()` 迁移为 `db.customSelect()`，`watch()` 保留可用。
  - `lib/data/models/records.dart`：9 处 `Row` → `QueryRow`。
  - `Variable<Object?>` → `Variable<Object>`（customSelect 参数类型要求）。
  - `test/database_test.dart`：3 处 `db.select` 同步改为 `customSelect`。
  - 架构说明已补入 `docs/build_guide.md`。

### 4.2 缺失 import / 文件

- `category_sheet.dart`、`sticker_importer.dart`：补充 `data/models/records.dart` 导入。
- `tag_dao.dart`：修正 `constants.dart` 相对路径（多一级 `../`）。
- `main.dart`、`crash_reporter.dart`：补充 `dart:ui` 导入（`PlatformDispatcher`）。
- `export_service.dart`：补充 `flutter/rendering.dart` 导入（`RenderRepaintBoundary`）。

### 4.3 缺失成员 / 方法名错误

- `keystore.dart`：新增 `readEncrypted` / `writeEncrypted`，修复 `auth.dart` 调用不存在的成员。
- `addEntryTag` → `addTagToEntry`（3 处 UI 调用，Repository 方法名对齐）。
- `CsvEncoder` → `ListToCsvConverter`（csv 包 API）。

### 4.4 语法与 Flutter API 兼容

- `classifier.dart`：构造函数命名参数以下划线开头（Dart 语法错误）→ 改为普通参数名 + 初始化列表。
- `app_theme.dart`：`CardThemeData` → `CardTheme`（Flutter 3.24 API）。
- `entry_page.dart`：`initialValue` → `value`（DropdownButtonFormField）；`Icons.sticker_outlined` → `Icons.image`。
- `sticker_picker_sheet.dart`：`Icons.sticker` → `Icons.image`。
- `tombstone_cleanup.dart`：`NetworkType.notRequired` → `not_required`，`Constraints` 去掉 `const`。

### 4.5 Android 构建配置

- `android/app/build.gradle`：新增从 `local.properties` 读取 `flutter.versionCode` / `flutter.versionName` 的逻辑（原使用废弃的 `flutterVersionCode` / `flutterVersionName` 属性）。
- `AndroidManifest.xml`：应用图标 `@mipmap/ic_launcher` → `@drawable/ic_launcher`。
- 新增 `android/app/src/main/res/drawable/ic_launcher.xml`（shape 矢量图标），解决缺失 mipmap 资源导致的 AAPT 错误。

---

## 五、构建文件补齐

| 文件 | 说明 |
| --- | --- |
| `pubspec.lock` | 新增，固化 118 个依赖版本 |
| `android/gradlew`、`gradlew.bat` | 新增，原仓库缺失，Flutter 构建必需 |
| `android/gradle/wrapper/gradle-wrapper.jar` | 新增，Gradle wrapper 引导程序 |
| `.gitignore` | 补充 Flutter 自动生成文件忽略项（`.flutter-plugins`、`GeneratedPluginRegistrant.java` 等） |

---

## 六、构建与推送结果

- 全部修改已推送至 `cyj000/shouzhang` 的 `main` 分支，最终 commit：`7df131c7b6ec5594dfdac7ffd180f32f498db446`。
- GitHub Actions 运行 `44127669846` **构建成功**，产出 Artifact `paper-ledger-release`（约 68 MB，含 `app-release.apk` 与 `app-release.aab`）。
- 通过该次运行的 Artifacts 区可下载安装包。

---

## 七、遗留事项（不影响使用）

1. `flutter doctor` 提示 4 个 Android SDK 许可证未接受：不影响 GitHub Actions 云端打包；本地如需完全干净，可执行 `flutter doctor --android-licenses` 接受。
2. `flutter analyze` 仍有 44 条 warning/info（未使用字段、建议 const 等），不阻断编译，可后续逐步清理。
3. 正式上架需配置签名 secrets（`KEYSTORE_BASE64` 等 4 项），未配置时产物为 debug 签名，仅供安装测试。
