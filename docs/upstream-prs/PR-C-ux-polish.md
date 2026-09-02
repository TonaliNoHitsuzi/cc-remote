# PR-C：polish: 按钮平台跳过冗余允许确认 + 取消 turn 的空响应静默

> 状态：文档就绪，待提交。两处独立小改进，可拆为两个 PR。
> 基线 b39c11f。

## 改动 1：skip redundant "Allowed" ack on inline-button platforms

### PR 标题

- polish(permission): skip "Allowed, continuing" ack on platforms with native inline buttons

### 背景

`handlePermissionTextReply`（core/engine.go）在用户批准权限后回复 `MsgPermissionAllowed`（"✅ 已允许，继续执行..."）。对实现了 `InlineButtonSender` 的平台（QQBot 键盘 / Telegram inline / Slack 等），权限请求本身就是带按钮的卡片，**客户端点击按钮自带 visited 态视觉反馈**，随后的文本确认是纯噪音——尤其权限密集的任务，每个"允许"都多一条消息，加重 IM 侧消息量（对有主动消息预算的平台是实打实的额度浪费）。

拒绝（MsgPermissionDenied）保留：CUJ 测试锁定"deny 后必须有用户可见反馈"（core/cuj_test.go:996），且失败场景确实需要显式回执。

### 实现

```go
} else if isAllowResponse(lower) {
	if err := state.agentSession.RespondPermission(...); err != nil {
		...
	} else if _, hasButtons := p.(InlineButtonSender); !hasButtons {
		// Platforms with native inline buttons already acknowledge the click
		// client-side (visited state); an extra text confirmation is noise.
		e.reply(p, msg.ReplyCtx, e.i18n.T(MsgPermissionAllowed))
	}
```

### 复现/验证

1. QQBot 平台（`markdown_support = true`，键盘按钮生效），触发跨目录权限请求
2. 修复前：点【允许】→ 收到"⏹/✅ 已允许，继续执行..."一条 + 后续正文
3. 修复后：点【允许】→ 仅后续正文（按钮 visited 态即反馈）
4. 文字回复"允许"路径同样静默（IM 侧用户可见自己的消息，无信息损失）；无按钮平台行为不变

## 改动 2：silence "(empty response)" for cancelled turns

### PR 标题

- fix(engine): don't emit "(empty response)" placeholder when a turn is cancelled via graceful ACP CancelTurn

### 背景

`/stop` 对 ACP 后端走优雅取消（`stopInteractiveSessionWithOptions` → `AgentSessionCanceller.CancelTurn`），agent 进程返回 `stopReason:"cancelled"` 且无任何正文。turn 收尾路径发现 fullResponse 为空 → 填入 `MsgEmptyResponse` 占位（"(空响应)"）并发送。

用户看到的效果（实测 QQBot）：

```
⏹ 执行已停止。      ← /stop 命令自己的确认（信息已足够）
(空响应)             ← 紧随其后的占位噪音 ← 本修复目标
```

engine.go 的注释明确 ACP 取消路径**故意不 markStopped**（"Don't markStopped — the session is still usable"，stopInteractiveSessionWithOptions:10359），因此不能用 isStopped() 判定，需要专用标志。

### 实现

1. `interactiveState` 增加 `turnCancelled bool`，在 CancelTurn 分支与 `eventsNeedResync` 同步置位：

```go
state.mu.Lock()
state.eventsNeedResync = true
state.turnCancelled = true
state.mu.Unlock()
```

2. 空响应占位处 read-and-clear 判定，命中则复用既有 NO_REPLY 静默通道（不发送、历史仍记录）：

```go
if fullResponse == "" {
	state.mu.Lock()
	cancelled := state.turnCancelled
	state.turnCancelled = false // read-and-clear
	stopped := state.stopped
	state.mu.Unlock()
	if cancelled || stopped {
		fullResponse = "NO_REPLY"
	} else {
		fullResponse = e.i18n.T(MsgEmptyResponse)
	}
}
```

read-and-clear 语义防止同会话后续**正常**空 turn 被误静默。

### 复现/验证

1. ACP 后端发长任务：`执行 sleep 90 然后汇报睡醒了`
2. 10 秒后发 `/stop`
3. 修复前：收到"⏹ 执行已停止。"+"(空响应)"两条
4. 修复后：仅"⏹ 执行已停止。"；随后发"刚才的任务是什么状态？"确认会话上下文保留（agent 能答出 sleep 任务被中止）

### 兼容性说明

- turn_timeout 路径（markStopped）行为不变且同样受益（stopped 条件）
- 非取消的正常空输出 turn 仍显示占位（read-and-clear 保证）
