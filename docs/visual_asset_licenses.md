# 视觉素材授权凭证登记（视觉专项 VPKG-01）

> 体积约束已解除（用户 2026-11-18 明确），字体采用完整字库直接打包，不做子集化。
> 本文件登记视觉专项引入的第三方素材及其授权，确保可商用合规。

## 1. 中文手写字体：霞鹜文楷（LXGW WenKai）

| 项 | 值 |
| --- | --- |
| 字体名称 | 霞鹜文楷 LXGW WenKai |
| 版本 | v1.520 |
| 上游 | https://github.com/lxgw/LxgwWenKai |
| 授权 | SIL Open Font License 1.1（OFL-1.1） |
| 可商用 | 是（OFL 允许商用、嵌入、再分发，禁止单独售卖字体本身） |
| 打包文件 | `assets/fonts/LXGWWenKai-Regular.ttf`（400）、`assets/fonts/LXGWWenKai-Medium.ttf`（500） |
| 授权原文 | `assets/fonts/OFL.txt`（随字体一同打包，pubspec 已登记为 asset） |
| 用途 | 标题 / 金额 / 情感文案的手写感呈现（Token：`AppTypography.handwritingFamily`） |
| 获取方式 | GitHub release v1.520 官方 TTF，下载日期 2026-11-18 |
| 校验 | 完整字库、未子集化、未修改字形；仅按 OFL 原样嵌入 |

### OFL 合规声明

- 字体以原样嵌入 App，未修改字形数据；
- 授权文件 OFL.txt 随包分发；
- 字体未单独出售；App 名称「纸间账」与字体保留字体名无冲突（OFL 保留字体名条款）；
- 正文字体使用系统默认无衬线，不额外引入第三方字体。

## 2. 贴纸素材

- 一期内置贴纸为程序化矢量自绘（`builtin://`），自绘即 CC0，见 `assets/stickers/manifest.json`。
- 外部素材导入仍走 `LicenseGuard`（仅 CC0 / CC BY），留痕见 `docs/license_audit.md`。

## 3. 插画 / 纹理

- 纸纹（`paper_texture.dart`）、空状态插画（`empty_state_art.dart`）均为代码自绘矢量，无外部素材、无授权风险。

---

> 任何后续新增字体 / 插画素材，必须先在本文件登记授权，再接入 Token，禁止业务代码直接使用来源不明的素材。
