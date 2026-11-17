# 纸间账 · 数据契约 v1.0（冻结）

> PKG-08 / FR-41。**一期仅冻结口径**，不实现同步执行、鉴权、开放接口完整能力。
> 本契约是二期的基线，任何变更须升版本号并走评审。

- 契约版本：`1.0`
- 冻结日期：2026-11-17
- 状态：**Frozen**（一期不做消费方对接）

## 1. Schema（对齐任务书 §3）

### 1.1 核心实体

| 实体 | 主键 | 关键字段口径 |
| --- | --- | --- |
| entries | id(UUID) | amount_cents INTEGER 分；revision 更新 +1；deleted 软删；五块冲突字段预留 |
| tags | id | name 唯一；is_system=1 不可删改名 |
| entry_tags | (entry_id, tag_id, source) | source ∈ 文本/贴纸/历史/手动；sticker_instance_id 用于精确回滚 |
| stickers | id | checksum 去重；removed_at/remove_reason 软删 |
| sticker_sources | sticker_id | license ∈ CC0/CC BY；license_check_shot 必填 |
| sticker_instances | id | asset_path_snapshot / attributes_snapshot_json 冗余快照 |
| ink_layers | id | strokes_json 增量指令数组 |
| oplog | (op_id, device_id) | 幂等键；lamport 逻辑时钟（一期仅本地写） |
| telemetry_events | id(auto) | 仅本地，禁止外发 |

### 1.2 金额口径

- 全链路 INTEGER 分；上限 100,000,000 分；展示格式化为元（两位小数）。
- 禁止 float/double 参与金额运算（R2）。

## 2. API（预埋边界）

| 能力 | 一期状态 | 说明 |
| --- | --- | --- |
| ContentProvider query/insert/update/delete | 骨架（exported=false） | 空实现，返回 null/0，无数据外泄面 |
| signature 权限 `READ_LEDGER` | 声明 | 仅同签名应用可声明，一期无消费方 |
| 授权同意页 / token / 审计 UI / 网关 | **不做** | 无确定第三方（I-1） |

## 3. 错误码（预留，一期不触发）

| 码 | 含义 | 一期状态 |
| --- | --- | --- |
| 401 | 未授权 | 预留 |
| 409 | 冲突 | 预留（二期合并算法用） |
| 410 | 已删除/过期 | 预留 |

## 4. 鉴权与同步协议

- 鉴权：二期基于 signature 权限 + 用户授权同意页；一期不实现。
- 同步协议：oplog 幂等键 `(op_id, device_id)` + lamport 逻辑时钟已落库；上报/拉取/合并算法二期实现。
- tombstone 保留期（90 天）须 ≥ oplog 保留期。

## 5. 埋点契约（第 6 章）

- 事件名锁定：record_start / record_save / classify_result / classify_tag_result / tag_edit /
  sticker_import / sticker_apply / review_filter / app_open。
- 一期仅本地落库，不上报（R7）。`sync_run / openapi_auth / openapi_call` 二期事件，一期不实现。

## 6. 预埋工时单列（REV-08 要求）

| 组 | 交付物 | 工时（估算） |
| --- | --- | --- |
| oplog | 表 + 写入时机 + 幂等键 | 0.5 人日 |
| 冲突字段 | entries 五块 version/hash 预留 | 0.25 人日 |
| ContentProvider | 声明 + signature 权限 + 空实现骨架 | 0.5 人日 |
| contract | 本文档冻结 | 0.25 人日 |
| 合计 | — | **1.5 人日** |

> 未实现项工时（同步/合并/鉴权/网关）不计入一期。
