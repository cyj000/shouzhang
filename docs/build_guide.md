# 纸间账 · 构建说明（PKG-01 锁定）

> 本文件是依赖版本与工程选型的**单一锁定记录**。锁定后不得中途变更；确需变更须走评审（任务书 §2.2）。

## 1. 环境与能力边界（诚实声明）

- **本环境无 Android SDK / Xcode**：本次交付为**代码级产物**。未在交付环境执行 `flutter pub get`、`flutter analyze`、编译、打包、真机运行。
- 真实构建/签名/真机测试/上架须在具备 Android SDK 的环境完成。性能指标均为**目标值**，需按 PKG-09 在真机实测校准。

## 2. 锁定版本（2026-11-17）

| 项 | 锁定值 |
| --- | --- |
| Dart SDK | `>=3.5.0 <4.0.0` |
| Flutter | 与 Dart 3.5+ 匹配的稳定版（建议 3.24+） |
| Android Gradle Plugin | `8.7.3` |
| Kotlin Gradle Plugin | `1.9.24` |
| Gradle Wrapper | `8.12-all` |
| compileSdk / targetSdk | `35` |
| minSdk | `23` |
| Java / Kotlin jvmTarget | `17` |
| 包名 | `com.paperledger.app`（占位，发布前确认） |

依赖（详见 `pubspec.yaml`）：

| 用途 | 依赖 | 锁定约束 |
| --- | --- | --- |
| ORM | `drift` / `drift_flutter` | `^2.22.0` / `^0.2.1` |
| 加密 | `sqlcipher_flutter_libs` | `^0.7.0` |
| 密钥/认证 | `flutter_secure_storage` / `local_auth` | `^9.2.2` / `^2.3.0` |
| 状态管理（**选型已锁定**） | `flutter_riverpod` | `^2.6.1` |
| 路由 | `go_router` | `^14.8.1` |
| 模型不可变 | 手写不可变类 + `freezed_annotation`（可选，未启用代码生成） | — |
| 金额解析 | 自写 `amount_parser`（int 分单位，禁 double） | — |
| CSV | `csv` | `^6.0.0` |
| 测试 | `flutter_test` + drift 内存库 | SDK 内置 |

> 说明：本环境无法访问 pub.dev 校验最新补丁版本；上述为已知稳定约束，首次构建时以 `flutter pub get` 实际解析结果为准并记录 `pubspec.lock`。锁定后不得改约束。

## 3. 关键决策记录

- **状态管理**：选 Riverpod。理由： Provider 声明式注入、易与 Repository/Usecase 分层、测试可直接覆盖 provider。
- **数据库**：采用 drift 的 **Dart-only 表定义**（不引入 build_runner 生成文件），保证工程在无生成步骤时也可分析通过。
- **加密**：SQLCipher AES-256；密钥链路 DQ-01（Keystore 生成主密钥 → 加密随机 passphrase → 密文落私有目录 → passphrase 开库），见 PKG-02。
- **金额**：全链路 int 分，展示层格式化两位小数；禁止 double/float 参与金额运算。
- **权限**：release Manifest 无 INTERNET / 定位 / 录音；INTERNET 仅 debug 热重载使用。相册/相机在 PKG-07 按需申请。

## 4. 构建命令（在具备 SDK 的环境执行）

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # 如启用 freezed 可选
flutter analyze
flutter test
flutter build apk --release          # 产出 build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release    # 上架用 AAB
```

签名：在 `android/key.properties` 配置 `keyAlias/keyPassword/storeFile/storePassword`（已 gitignore），`android/app/build.gradle` 会自动读取；未配置时 release 回退 debug 签名，**仅供本地验证，禁止上架**。

## 5. 真机基线

- 开发/测试真机：realme GT5 Pro（RMX3888）/ 骁龙 8 Gen3 / Android 16（当前唯一测试机型）。
- 性能目标值（PKG-09 实测校准）：启动 <1s、键盘 <300ms、落笔 <50ms、列表 ≥55fps。
- 性能数据标注"旗舰机型实测"，不作全档位承诺（RK-13）。

## 6. ⚠️ 待确认项（按默认值实现，交付时汇总）

| 项 | 默认值 | 决策建议 |
| --- | --- | --- |
| 状态管理选型 | Riverpod | 如团队已用 Bloc 可评审切换 |
| 包名 | `com.paperledger.app` | 发布前确认开发者账号归属 |
| 依赖补丁版本 | 见上表约束 | 首次 `pub get` 后固化 lock 文件 |
