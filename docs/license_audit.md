# 贴纸开源许可留痕（PKG-05 / R3）

## 1. 白名单规则

- 仅允许 **CC0 / CC BY**；**CC BY-SA / CC BY-NC / 来源不明 / 许可原文缺失** 一律拒绝。
- 校验入口：`lib/features/sticker/license_guard.dart`，由 `sticker_importer.dart` 在入库前调用。
- 每张贴纸须留存：来源 URL、许可原文、获取日期、作者、**许可核对截图路径**。

## 2. 一期内置素材清单

| ID | asset_path | 许可 | 来源 | 核对截图 |
| --- | --- | --- | --- | --- |
| builtin_coffee | `builtin://coffee` | CC0 | 本项目程序化自绘（矢量图标 + 配色） | 内置清单 `assets/stickers/manifest.json` |
| builtin_food | `builtin://food` | CC0 | 同上 | 同上 |
| builtin_bus | `builtin://bus` | CC0 | 同上 | 同上 |
| builtin_book | `builtin://book` | CC0 | 同上 | 同上 |
| builtin_gift | `builtin://gift` | CC0 | 同上 | 同上 |
| builtin_home | `builtin://home` | CC0 | 同上 | 同上 |

> 说明：一期未引入任何第三方二进制贴图，故不存在来源不明素材；自绘图标按 CC0 处理。
> 若后续接入第三方素材，必须逐张核对许可原文、保存截图，并在此表追加行。

## 3. 导入流程（FR-14~16）

1. 用户/运营提供素材字节、来源 URL、许可字符串、许可核对截图路径。
2. `LicenseGuard.check` 白名单校验，任一不满足直接拒绝并写 `sticker_import` 埋点 `result=rejected_*`。
3. `Cipher.checksumOf` 计算 SHA-256；命中已有 checksum → 去重复用，埋点 `result=duplicate`。
4. 通过后写 `stickers` + `sticker_sources`（来源留痕完整），埋点 `result=accepted`。

## 4. 违规处理

- 已入库素材发现许可不符：`StickerRepository.softDelete(id, reason)` 软删（保留审计），预设库查询过滤 `removed_at IS NULL`。
- 历史贴纸实例靠 `asset_path_snapshot` / `attributes_snapshot_json` 继续渲染与统计（DQ-08）。

## 5. ⚠️ 待确认

- 「逐张核对截图」一期以路径留痕，`docs/license_audit.md` 为人工核对台账；如需自动 OCR 校验许原文，属二期范围。
