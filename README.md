# 纸间账 · paper_ledger

> 纯本地手账记账 App（一期 Android only）。数据只存设备、不出设备；没有账号、不联网、不申请定位/录音权限。

---

## 功能特性

### 极速记账
- 自定义数字键盘，算式记账（如 `25+8`），金额按「分」整数存储，杜绝浮点误差（0.1+0.2 精确等于 0.30）
- 冷启动直落记账页，默认免密，贴合手账单手极速记录场景
- 固定竖屏，贴合手账本使用习惯

### 智能分类
- 备注语义 + 贴纸属性 + 历史习惯 → 多标签自动分类
- 未命中自动挂「未分类」，支持负反馈（降权），系统标签不可删/改名

### 贴纸与涂鸦
- 内置程序化矢量贴纸（CC0），支持导入外部贴纸并做开源许可白名单校验（仅 CC0 / CC BY）
- checksum 去重，软删除保留历史实例快照，撤销贴纸时按实例精确回滚关联标签，不误删文本/历史来源
- Skia 增量笔迹图层（存指令数组而非整图）

### 多维回顾与导出
- 5 类统计视图，按标签联动筛选，分单位整数统计
- 导出 CSV / 图片到应用私有目录，不申请存储权限、不外发

### 隐私与安全
- SQLCipher AES-256 加密数据库，密钥链路基于 Android Keystore
- release 版 Manifest 无 INTERNET 权限；埋点仅本地落库，禁止外发
- 可选锁屏认证（默认关闭）：生物识别/设备密码 + 5 分钟宽限期
- 权限最小化：相册/相机按需申请，无定位、无录音

### 架构预埋（二期）
- 9 张数据表 + 索引、五块冲突字段预留、oplog 幂等键 + lamport 逻辑时钟
- ContentProvider 骨架（exported=false，空实现）、signature 级权限声明、数据契约 v1.0 已冻结

> 红线：数据不出设备、金额分单位整数、开源许可白名单、不做清单（无定位/录音/同步/开放接口）、默认免密、权限最小化、埋点仅本地。

---

## 技术栈

| 项 | 版本 / 选型 |
| --- | --- |
| Flutter / Dart | 3.24.5 / 3.5.4 |
| 状态管理 | Riverpod |
| 路由 | go_router |
| 本地数据库 | drift（Dart-only 表定义）+ SQLCipher |
| 密钥 / 认证 | flutter_secure_storage + local_auth |
| 后台任务 | workmanager |

---

## 构建与打包

项目已配置 GitHub Actions 自动打包：

- **手动触发**：在仓库 Actions 页运行 `Android Release Build`
- **自动触发**：推送 `v*` 标签
- **产物**：同时产出 `app-release.apk`（可直接安装）和 `app-release.aab`（上架用），上传到该次运行的 Artifacts；tag 触发时自动创建 GitHub Release

### 本地构建

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release      # build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release
```

本地环境需 Flutter 3.24.5 + JDK 17 + Android SDK 35。签名可选：在 `android/key.properties` 配置 `keyAlias/keyPassword/storeFile/storePassword`（已 gitignore），未配置时 release 回退 debug 签名，仅供本地验证。

### 下载安装包

打开仓库 Actions 页，进入成功的 `Android Release Build` 运行，在页面底部的 Artifacts 区下载 `paper-ledger-release`（zip，解压即得 APK/AAB）。

---

## 文档索引

| 文档 | 说明 |
| --- | --- |
| [docs/build_guide.md](docs/build_guide.md) | 构建说明与依赖版本锁定记录 |
| [docs/DELIVERY.md](docs/DELIVERY.md) | 一期交付清单与 DoD 自检 |
| [docs/contract_v1.0.md](docs/contract_v1.0.md) | 数据契约 v1.0（冻结） |
| [docs/privacy_notes.md](docs/privacy_notes.md) | 隐私要点 |
| [docs/license_audit.md](docs/license_audit.md) | 贴纸开源许可审计 |
| [docs/perf_baseline.md](docs/perf_baseline.md) | 性能基线（目标值，待真机校准） |
| [docs/telemetry_audit.md](docs/telemetry_audit.md) | 埋点审计 |
| [docs/CHANGELOG_2026-11-18.md](docs/CHANGELOG_2026-11-18.md) | 2026-11-18 变更说明（环境搭建、打包流水线、编译修复等） |
