# PR-B：feat(acp): 实现 ContextUsageReporter（真实上下文占用上报）

> 状态：文档就绪，待提交。关联上游 open issues **#1672**（ctx footer 硬编码 200k 窗口）与 **#1764**（auto-compress 用文本估算，漏掉 70-85% 真实上下文）。
> 基线 b39c11f。

## PR 标题（中英）

- feat(acp): report real context usage from opencode `usage_update` + prompt usage (implements ContextUsageReporter, mitigates #1672 / #1764)

## 问题背景

core 引擎已有 `ContextUsageReporter` 可选接口（core/interfaces.go:494+）与完整 `ContextUsage` 结构（UsedTokens / CachedInputTokens / CacheCreationInputTokens / ContextWindow 等），`replyFooterContextText` / auto-compress 触发逻辑都会优先采用它。但 **ACP agent 未实现该接口**，导致：

1. `[ctx: ~N%]` footer 走 `contextIndicatorText(event.InputTokens)` 文本估算（#1672：大窗口模型固定显示 ~100%）
2. auto-compress 触发估算漏掉 tool_use/tool_result 与 system prompt 开销（#1764）

而 opencode 的 ACP 端**恰好持续上报两类真实数据**：

- `session/update` 通知 `usage_update`：`{"used": 8606, "size": 200000}`（当前上下文累计 / 模型窗口）
- `session/prompt` 响应 `usage`：`{"inputTokens":158, "outputTokens":33, "totalTokens":8639, "cachedReadTokens":8448}`（逐 turn 精确值，含缓存命中）

## 实现（agent/acp/session.go）

1. `acpSession` 增加字段：`usageMu sync.RWMutex; lastUsage core.ContextUsage; haveUsage bool`
2. `onNotification` 中新增 `maybeAbsorbUsageUpdate(params)`：识别 `sessionUpdate == "usage_update"`，吸收 `used` → UsedTokens、`size` → ContextWindow（与既有 `maybeAbsorbCurrentModeUpdate` 同构，遵循锁与解析模式）
3. `session/prompt` 响应后吸收 `usage.cachedReadTokens/inputTokens/outputTokens/totalTokens`（CachedInputTokens 是 footer 缓存命中的唯一来源）
4. 实现 `GetContextUsage() *core.ContextUsage`（快照返回）

```go
func (s *acpSession) GetContextUsage() *core.ContextUsage {
	s.usageMu.RLock()
	defer s.usageMu.RUnlock()
	if !s.haveUsage {
		return nil
	}
	cu := s.lastUsage
	return &cu
}
```

## 实测效果（GLM-5.3，1M 窗口）

footer 从估算（issue #1672 病症）：

```
[ctx: ~1%]   ← 200k 硬编码下的估算
```

变为真实数据（本 PR 附带的 footer 渲染示例）：

```
上下文: 14.7k / 1.0M (1%)
缓存: 14.7k (99%)
```

（缓存 99% = cachedReadTokens/used，对用户判断"这轮是不是几乎全走了缓存"非常直观。）

对 #1764：引擎 auto-compress 分支 `if usage := replyFooterSessionContextUsage(state.agentSession); usage != nil && usage.UsedTokens > 0 { estimate = usage.UsedTokens }` ——本 PR 使该分支对 ACP 后端生效，触发阈值从"文本估算"升级为 API 上报真值。

## 复现指南

1. 接入 opencode ACP（同 PR-A 环境），DEBUG 日志确认两类数据到达：

```
level=DEBUG msg="acp: session/update" params="{...\"sessionUpdate\":\"usage_update\"...\"used\":8606,\"size\":200000...}"
level=DEBUG msg="acp: session/prompt response" response="{\"stopReason\":\"end_turn\",\"usage\":{\"inputTokens\":158,...\"cachedReadTokens\":8448}...}"
```

2. 修复前：footer ctx 值来自估算（可对比 turn complete 日志的 input_tokens 与 footer 百分比是否基于真实窗口）
3. 修复后：footer 显示 used/size 精确量纲与百分比；auto-compress 阈值按 UsedTokens 触发

## 兼容性说明

- 仅在 opencode 发送 usage_update 时激活；其他 ACP 后端（Cursor/Trae 等不发该事件）GetContextUsage 返回 nil，行为与现状完全一致（引擎已有 nil 降级路径）
- 不改变 quiet/full 任何显示模式语义，仅替换数据源

## 附：可选的 footer 展示增强（可拆分讨论）

本仓库同时改了 `buildClaudeStatusLineFooter` 的展示格式（分行标签式），这部分是主观体验优化，可按维护者偏好拆出或舍弃——数据层（本 PR 核心）与展示层解耦，`contextUsageRichText` 为独立函数。
