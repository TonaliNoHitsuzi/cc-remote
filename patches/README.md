# 补丁说明

`cc-remote-local.patch`：基于 cc-connect **b39c11f**（2026-08-31 main）的本地增强，5 项改动、3 个文件（153+/31-），已在干净基线验证可应用。

| # | 文件 | 内容 |
|---|---|---|
| 1 | agent/acp/mapping.go | `agent_thought_chunk` → EventThinking（opencode 思维链事件名与 cc-connect 期望不符，被当正文泄漏） |
| 2 | core/engine.go | 按钮平台跳过"已允许"冗余确认 |
| 3 | core/engine.go | `turnCancelled` 标志：ACP 优雅取消后空 turn 走 NO_REPLY 静默（无"(空响应)"噪音） |
| 4 | agent/acp/session.go | 实现 ContextUsageReporter：吸收 usage_update{used,size} 与 prompt response{cachedReadTokens} |
| 5 | core/engine.go | footer 分行标签式（模型/上下文 量+百分比/缓存命中），真实数据优先于估算 |

应用方式：`scripts/build-cc-connect.sh`（clone → checkout b39c11f → apply → docker golang 编译）。
上游 PR 计划中；若某补丁已进上游，脚本会跳过并提示。
