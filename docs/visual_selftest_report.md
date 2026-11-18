# 视觉专项 · 无环境自测报告（VPKG-06）

> 生成日期：2026-11-18　任务书：《手账记账 App · 视觉风格 AI 开发任务书 v1.0》
> 执行命令：`python visual_selftest.py --src d:\myproject\手账`
> 机器可读报告：`docs/visual_selftest_report.json`

## 1. 诚实边界（S4/S5/S6）

本环境无 Android SDK / Xcode。以下**做了**与**未做**如实声明：

- ✅ 已做：S1 静态结构扫描、S2 WCAG 对比度纯 Python 计算、S3 文档化合规检查、S4 逻辑单测代码编写。
- ❌ 未做（如实标注，待真机）：S5 Golden 截图基线、S6 真机性能（冷启动/键盘/帧率）、S4 测试的实际执行。
- 因此本报告**不代表**"已构建 / 已在真机验证"。所有构建相关验证需在有 Flutter 环境的 CI/真机完成。

## 2. 自测结果汇总

| 层级 | 检查项 | 结果 | 说明 |
| ---- | ------ | ---- | ---- |
| S2 | inkPrimary on paperBg（正文/金额） | PASS | 6.79:1 ≥ 4.5 |
| S2 | inkPrimary on paperCard（卡片正文） | PASS | 7.31:1 ≥ 4.5 |
| S2 | inkSecondary on paperBg（次要） | PASS | 5.09:1 ≥ 4.5 |
| S2 | 白字 on accentCoralDeep（主按钮） | PASS | 5.66:1 ≥ 4.5 |
| S2 | coral on paperBg（大字/图形） | PASS | 3.58:1 ≥ 3.0 |
| S2 | mint on paperBg（大字/图形） | PASS | 3.51:1 ≥ 3.0 |
| S1 | 源码 Token 色值与脚本一致 | PASS | 无漂移 |
| S1 | 9 个 Token/decor 文件齐全 | PASS | 6 + 3 |
| S1 | 业务代码无硬编码色值 | PASS | 零命中（仅 app_colors.dart 允许写色值） |
| S1 | 业务代码无字号/圆角魔法数 | PASS | 零命中 |
| S1 | MaterialApp 接入 AppTheme.light() | PASS | lib/app.dart |
| S3 | 全局动效开关存在且接入设置页 | PASS | motionEnabledProvider |
| S3 | pubspec 字体声明 | PASS | fonts: 段 |
| S3 | 字体授权凭证登记 | PASS | docs/visual_asset_licenses.md |
| S3 | 字体文件与 OFL 随包 | PASS | Regular TTF 24.7MB + OFL |
| S1 | 内置贴纸 ≥ 20 款 | PASS | 实际 25 款 |

**汇总：PASS=16，FAIL=0，WARN=0。退出码 0。**

## 3. 对比度实测值（WCAG 2.1）

脚本内置色值与 `lib/core/theme/app_colors.dart` 逐项比对一致，实测结果与任务书 §2.5 校准目标吻合：

| 色对 | 实测 | 阈值 | 判定 |
| ---- | ---- | ---- | ---- |
| inkPrimary / paperBg | 6.79:1 | 4.5 | 达标 |
| inkPrimary / paperCard | 7.31:1 | 4.5 | 达标 |
| inkSecondary / paperBg | 5.09:1 | 4.5 | 达标 |
| onPrimary / accentCoralDeep | 5.66:1 | 4.5 | 达标 |
| accentCoral / paperBg | 3.58:1 | 3.0 | 达标 |
| accentMint / paperBg | 3.51:1 | 3.0 | 达标 |

> 后续任何调色必须重跑 `python visual_selftest.py --src <path>`，确认 16 项全 PASS 方可合入。

## 4. DoD 逐条核对（任务书第 6 章）

| # | 检查项 | 状态 | 证据 |
| - | ------ | ---- | ---- |
| 1 | Token 单一事实源 | 达成 | 脚本硬编码扫描零命中 |
| 2 | 分层落地 | 静态达成 | L0 diff 仅换肤；L1/L2 装饰已接入；真机视觉待验 |
| 3 | 速度红线 | 静态达成 | L0 无新增动画、无交互改动；真机项 T1~T3 待测 |
| 4 | 对比度 | 达成 | 6 色对全达标 |
| 5 | 无障碍 | 静态达成 | 动效可关、textScaler clamp 1.3、caption 11sp；真机 T5 待测 |
| 6 | 素材合规 | 达成 | 贴纸自绘 CC0；字体 OFL 随包；凭证齐全 |
| 7 | 自测归档 | 达成 | 本报告 + JSON + 走查清单 |
| 8 | 边界声明 | 达成 | 未声称构建/真机验证 |

## 5. 待真机项（不可在本环境完成）

| # | 项 | 环境要求 | 验收标准 |
| - | -- | -------- | -------- |
| T1 | 冷启动到首屏 | 真机 realme GT5 Pro | <1s，改造前后无退化 |
| T2 | 键盘弹出耗时 | 真机 | <300ms |
| T3 | 连续录入 3 笔 | 真机 | 步数不变、无新增等待 |
| T4 | Golden 截图基线 | 模拟器/真机 | 各页视觉效果符合设计稿 |
| T5 | 放大字体渲染 | 真机 | 金额可辨、布局不溢出 |
| T6 | 动效流畅度 | 真机 | 无掉帧，关闭开关生效 |

> 真机数据须标注"旗舰机型实测"（RK-13），不作全档位承诺。
