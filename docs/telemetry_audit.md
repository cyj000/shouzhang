# 埋点完整性审计（PKG-09 / 第 6 章）

> 一期埋点**仅本地落库，不上报、不出设备**（R1/R7）。本文档说明事件字典、口径与完整性校验。

## 1. 事件字典（锁定，R8）

| 事件名 | 触发时机 | 必填字段 |
| --- | --- | --- |
| record_start | 进入记账页（首笔） | ts, device_id |
| record_save | 保存成功 | ts, amount_range, tag_count, duration_ms, offline, entry_index, is_continuous |
| classify_result | 分类生成（单笔汇总） | ts, entry_id, tag_count, hit |
| classify_tag_result | 每条建议标签一行（明细） | entry_id, tag_name, source, confidence, kept |
| tag_edit | 用户增删标签 | action, tag_name, source, entry_id |
| sticker_import | 素材导入入库 | source_url, license, attribute_count, result |
| sticker_apply | 贴纸贴附/取消 | sticker_source, action, tag_merged_count |
| review_filter | 回顾筛选 | tag_names, view_type |
| app_open | App 打开 | ts, device_id, install_days |

**二期事件（一期不实现）**：sync_run / openapi_auth / openapi_call。

## 2. 关键口径

- **命中率** = `classify_tag_result` 中 kept=1 条数 ÷ 有效建议条数（排除 `未分类`）；
  kept 以保存成功时刻最终状态为准（删后加回仍算保留）。
- **单笔耗时**：连续笔 = 本笔 record_save.ts − 上一笔 record_save.ts；首笔 = record_save.ts − record_start.ts；
  取 P50/P90，对外以连续笔为主口径。
- **7 日回访率** = 安装后第 7 日仍打开的设备 ÷ 累计安装设备（观察指标，不设硬目标）。
- **完整率** = 必填字段齐全的事件数 / 总事件数，目标 **≥95%**。

## 3. 实现方式

- 事件字典构造：`lib/telemetry/events.dart`（字段名以方法参数固化，防发明口径）。
- 本地落库：`lib/telemetry/local_logger.dart` → `TelemetryRepository.track` → `telemetry_events` 表。
- 审计计算：`lib/telemetry/audit.dart` 的 `TelemetryAudit`（命中率 / 完整率 / 回访率）。
- 校验测试：`test/telemetry_audit_test.dart`、`test/gwt_scenarios_test.dart`。

## 4. 完整率校验结果

| 项 | 目标 | 校验方式 | 结果 |
| --- | --- | --- | --- |
| 事件完整率 | ≥95% | `TelemetryAudit.completeness` | 单测通过；真机全量校验待 PKG-09 实测 |
| 命中率可计算 | 是 | `TelemetryAudit.hitRate` | 单测通过（2/3、排除未分类） |
| 7 日回访率可计算 | 是 | `TelemetryAudit.day7ReturnRate` | 单测通过 |

## 5. 外发检查（R1/R7）

- release Manifest 无 INTERNET 权限（仅 debug 热重载声明）。
- 埋点库无任何网络出口；审计仅读本地表。
- 静态检查：代码库无用户数据网络写入调用。
