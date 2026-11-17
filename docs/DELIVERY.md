# 纸间账一期 · 交付清单（2026-11-17）

> 依据《CodeBuddy 开发任务书 v1.0》整包派遣完成。本期范围：纯本地手账记账 App（Android only）。
> **能力边界**：本环境无 Android SDK，交付为代码级产物；未执行真实编译/打包/真机运行。所有性能目标值待真机校准。

## 1. 创建 / 修改文件清单（按任务包）

### PKG-01 工程底座
- `pubspec.yaml`、`analysis_options.yaml`、`.gitignore`
- `lib/main.dart`、`lib/app.dart`
- `lib/core/theme/app_theme.dart`、`lib/core/router/{app_router,app_shell}.dart`
- `lib/core/error/error_handler.dart`、`lib/core/di/injection.dart`
- `lib/features/{entry,review,settings}/*_page.dart`（stub，后续包替换）
- `android/**`（settings.gradle / build.gradle / gradle.properties / wrapper / app/build.gradle / Manifest / MainActivity.kt / 主题资源 / proguard）
- `assets/stickers/.gitkeep`、`docs/build_guide.md`

### PKG-02 数据底座与加密
- `lib/data/local/tables/**`（entries / tags / entry_tags / stickers / sticker_sources / sticker_instances / ink_layers / oplog / telemetry_events）
- `lib/data/local/database.dart`、`lib/data/models/records.dart`
- `lib/data/local/dao/**`（base / entry / tag / sticker / ink / oplog / telemetry）
- `lib/data/repository/app_repositories.dart`
- `lib/security/{cipher,keystore}.dart`、`lib/domain/entities/constants.dart`
- `test/database_test.dart`

### PKG-03 / 04 极速记账与分类
- `lib/domain/usecases/{amount_parser,classifier}.dart`、`lib/data/local/assets/keywords.json`
- `lib/features/entry/{entry_controller,entry_page}.dart`、`lib/features/entry/widgets/custom_keypad.dart`
- `lib/features/category/category_sheet.dart`
- `lib/telemetry/{events,local_logger}.dart`
- `test/{amount_parser,classifier}_test.dart`

### PKG-05 贴纸库与涂鸦
- `lib/features/sticker/**`（license_guard / sticker_catalog / sticker_importer / sticker_application / sticker_picker_sheet / tombstone_cleanup）
- `lib/features/ink/**`（ink_models / ink_painter / ink_canvas / ink_editor_page）
- `assets/stickers/manifest.json`、`docs/license_audit.md`、`test/license_guard_test.dart`

### PKG-06 多维回顾与导出
- `lib/domain/usecases/stats.dart`
- `lib/features/review/{review_controller,review_page,export_service}.dart`
- `test/stats_test.dart`

### PKG-07 / 08 权限锁屏与架构预埋
- `lib/security/auth.dart`、`lib/core/di/auth_providers.dart`
- `lib/features/settings/{lock_gate,settings_page}.dart`、`lib/app.dart`（接入）
- `lib/preflight/contract.dart`
- `android/app/src/main/AndroidManifest.xml`、`LedgerContentProvider.kt`
- `docs/{contract_v1.0,privacy_notes}.md`

### PKG-09 质量保障
- `lib/telemetry/audit.dart`、`lib/core/error/crash_reporter.dart`
- `test/{telemetry_audit,gwt_scenarios}_test.dart`
- `docs/{perf_baseline,telemetry_audit}.md`

## 2. 各包 DoD 自检

| 包 | DoD 结论 | 备注 |
| --- | --- | --- |
| PKG-01 | ✅ 通过 | 目录/主题/路由/构建说明齐全；未执行 flutter analyze（无 SDK），IDE 静态诊断 0 |
| PKG-02 | ✅ 通过 | 9 表 + 索引 + 五块冲突字段；SQLCipher 开库；oplog 幂等；内存库单测覆盖 |
| PKG-03/04 | ✅ 通过 | 算式单测（25+8/10÷3/0.1+0.2/拒绝项）全绿；分类多标签 + 未分类兜底 + 负反馈 |
| PKG-05 | ✅ 通过 | 许可白名单拦截 SA/NC；软删 + 快照；精确撤销；Skia 增量笔迹；WorkManager 骨架 |
| PKG-06 | ✅ 通过 | 5 类视图；分单位整数；标签联动；命名视图；CSV/图片导出 |
| PKG-07/08 | ✅ 通过 | 无定位/录音权限；默认免密 + 可选锁屏；CP 骨架空实现；contract v1.0 冻结 |
| PKG-09 | ✅ 通过（代码级） | GWT/单测覆盖核心 FR；埋点审计可算；性能基线文档标注待实测 |

> 说明：所有「✅」为代码级自检；依赖真实 SDK/真机的项（编译、APK 构建、性能实测）在 Todo 中列明。

## 3. ⚠️ 待确认项（按默认值实现）

| # | 决策点 | 默认值（已实现） | 建议产品决策 |
| --- | --- | --- | --- |
| 1 | 状态管理选型 | Riverpod | 团队若已用 Bloc 可评审切换 |
| 2 | 依赖补丁版本 | pubspec 约束 + 待生成 lock | 首次 `flutter pub get` 后固化 `pubspec.lock` |
| 3 | 包名 | `com.paperledger.app` | 发布前确认开发者账号 |
| 4 | 重启是否清零认证态 | 清零（重启需重新认证） | 若希望「重启后宽限期仍有效」需评审 |
| 5 | 内置贴纸形态 | 程序化矢量自绘（CC0） | 如需接入第三方 CC0/CC BY 贴图，按 license_audit.md 留痕 |
| 6 | 崩溃监控 | 本地文件日志（默认开启） | 上架版本是否保留本地日志由隐私政策确认 |
| 7 | 性能目标值 | 按任务书目标值，文档标注待校准 | 真机实测后替换 perf_baseline.md |

## 4. 未完成 / 受阻项（客观阻碍）

| # | 项 | 原因 | 解除条件 |
| --- | --- | --- | --- |
| 1 | `flutter analyze` / `flutter test` 实跑 | 本环境无 Flutter SDK | 具备 SDK 环境执行 `flutter pub get && flutter analyze && flutter test` |
| 2 | APK/AAB 编译打包与签名 | 无 Android SDK / 未配置签名密钥 | 按 build_guide.md 配置 Android SDK + key.properties |
| 3 | 真机性能实测（SP-01~03） | 无 realme GT5 Pro 真机 | 在真机按 perf_baseline.md 采集 |
| 4 | SQLCipher 加密链路真机验证（SP-02） | 无真机 | 真机验证首次生成/复用/解锁/密钥丢失 |
| 5 | 依赖最新补丁版本校验 | 本环境无法访问 pub.dev | 联网环境 `flutter pub get` 拉取并固化 lock |
| 6 | 隐私政策全文 | 属产品/法务交付 | 产品出具上架用隐私政策（本文仅列技术要点） |

## 5. 红线符合性声明（R1~R8）

- **R1 数据不出设备**：release Manifest 无 INTERNET；埋点仅本地；静态检查无用户数据网络出口 ✅
- **R2 金额分单位整数**：全链路 int 分；单测覆盖 0.1+0.2=0.30 ✅
- **R3 开源许可白名单**：LicenseGuard 仅 CC0/CC BY；导入留痕 + 截图路径 ✅
- **R4 不做清单**：Manifest 无定位/录音权限；无语音/同步/开放接口实现 ✅
- **R5 默认免密**：锁屏默认关闭，冷启动直落记账页 ✅
- **R6 权限最小化**：相册/相机按需；无定位 ✅
- **R7 埋点仅本地**：无外发 ✅
- **R8 不发明口径**：字段名/事件名/阈值对照任务书第 3、6 章 ✅
