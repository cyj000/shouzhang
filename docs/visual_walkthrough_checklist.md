# 视觉专项 · 文档化走查清单（S3）

> 用途：无 SDK 环境下按"描述式验收"逐页走查。有环境时对照 Golden/真机复核。
> 状态标记：`[x]` 静态代码审查通过 / `[ ]` 待真机视觉确认。

## L0 速度层（记账页、保存反馈）—— 只换皮肤

- [x] 记账页背景为暖纸底色（`colorPaperBg`，ThemeData.scaffoldBackgroundColor）
- [x] 金额字号改用 `AppTypography.amountStyle`（36sp，body 字体保证 1/7、0/O 可辨）
- [x] 金额区无纸纹叠加（PaperTexture 未接入 L0）
- [x] 键盘按钮圆角/暖色来自 Token，未用系统默认灰
- [x] **无交互代码改动**：initState 焦点请求、save 时序、onPressed 逻辑 diff 未变
- [x] **无新增动画**：L0 未接入 StickerFrame/动效
- [ ] 真机：冷启动 <1s、键盘弹出 <300ms、连续 3 笔无新增等待（T1/T2/T3）

## L1 表达层（贴纸库、贴附区、涂鸦）

- [x] 内置贴纸 25 款生活物件（≥20），风格统一（程序化矢量自绘 / CC0）
- [x] 贴纸落下微动效接入 StickerFrame，时长 `motionFast`(150ms) + `curveSoft`
- [x] 胶带装饰接入（TapeStrip，±4° 旋转）
- [x] 搜索空结果有情感化空状态（EmptyStateArt）
- [x] **软删回归**：apply/undo 走 assetPathSnapshot 冗余快照，历史实例照常渲染（REV-05 未破坏）
- [x] 涂鸦页内边距改用 Token（AppTheme.spaceM）
- [ ] 真机：动效流畅无掉帧，关闭开关后即时到位（T6）

## L2 情感层（回顾、空状态、异常态、设置）

- [x] 回顾页便签卡片 + 胶带排版（`TapeStrip` 叠在图表卡上）
- [x] 图表数据可读优先：条形仍为横向比例条，金额/次数文案未变
- [x] 空账本：生活插画 + 引导文案（EmptyStateArt）
- [x] 空视图：情感化提示，无歧义
- [x] 异常态（锁屏）提示温和、可恢复，色值用 `AppColors.error`
- [x] 设置页新增"界面动效"开关，可一键关闭全部装饰动效
- [x] 各页无纯白/冷灰背景残留（背景统一 paperBg / paperCard）
- [ ] 真机：空/少/多三态数据下版式不溢出（T4）

## 全局无障碍

- [x] 动效可关（motionEnabledProvider 下发到 StickerFrame 与设置页）
- [x] 正文对比度 ≥4.5:1（脚本实测 6 色对全达标）
- [x] 辅助字号 ≥11sp（AppTypography.sizeCaption = 11）
- [x] 放大字体：`app.dart` 用 `textScaler.clamp(maxScaleFactor: 1.3)` 防排版撑破
- [ ] 真机：系统放大字体下金额可辨、布局不溢出（T5）

## 素材合规

- [x] 贴纸全部程序化矢量自绘（CC0），manifest 留痕
- [x] 中文手写字体霞鹜文楷（OFL 1.1），完整字库打包，未子集化
- [x] OFL 原文随包 + 授权凭证文档登记
- [x] 外部素材仍走 LicenseGuard（CC0/CC BY）

---

> 静态审查基于源码与自测脚本，不等同真机视觉验收。所有 `[ ]` 项须在有 Android SDK / 真机环境完成并回填结论。
