# PR-A：fix(acp): opencode 的思维链事件被误判为正文

> 状态：文档就绪，待提交。一行修复，影响所有 opencode ACP 用户。
> 预期目标分支：main（基线 b39c11f，2026-08-31）

## PR 标题（中英）

- fix(acp): map opencode's `agent_thought_chunk` to EventThinking (thinking currently leaks into replies)

## 问题背景

opencode（sst/opencode）的 ACP 端通过 `session/update` 通知推送 `agent_thought_chunk` 事件（模型思维链/内部独白流式片段）。

cc-connect 的 ACP 映射层 `mapSessionUpdate`（agent/acp/mapping.go）主 switch 只识别 `agent_message_chunk / tool_call / tool_call_update / plan / user_message_chunk`；未知类型进入 `mapSessionUpdateFallback`，其 EventThinking 识别列表为：

```go
case "reasoning", "reasoning_chunk", "thinking", "agent_thinking_chunk":
```

opencode 的实际事件名是 **`agent_thought_chunk`**（thought 而非 thinking），不在列表中 → 落入 fallback 的 last-resort 分支（mapping.go:285+），该分支会**提取任意 text 字段并作为 `core.EventText`（正文）返回** → 思维链内容被引擎当作 assistant 正文投递到 IM。

## 实际影响（实测日志）

环境：cc-connect main@b39c11f + opencode v1.18.26（ACP）+ QQBot 平台 + `[display] mode="quiet"`

用户收到的回复开头混入模型独白（原文摘录）：

```
Let me run the commands in parallel. The user asked me to count how many .md files ...
Now I need to respond following the qq-style rules - 本次工作流程
1. ...
```

根因链路（serve.log DEBUG）：

```
level=DEBUG msg="acp: session/update" params="{...\"sessionUpdate\":\"agent_thought_chunk\",\"content\":{\"type\":\"text\",\"text\":\"Let me run the commands in parallel.\"}..."
```

→ `mapSessionUpdateFallback: unrecognized format`（未命中 thinking 列表）→ last-resort 提取为 EventText → 进入 quiet 正文缓冲 → turn 结束时随正文一起发出。

对 display mode 的影响：
- `quiet`：独白混入合并正文（如上）
- `full`：独白被当作独立正文消息逐条发送，消息量剧增（实测单任务 10+ 条中间消息，多数为 thought）
- 无论何种模式，`thinking_messages=false` 均无法过滤（因为已被标为 EventText）

## 修复

```diff
--- a/agent/acp/mapping.go
+++ b/agent/acp/mapping.go
@@ -232,7 +232,7 @@ func mapSessionUpdateFallback(sessionID string, kind string, update json.RawMess
 	switch strings.ToLower(kind) {
-	case "reasoning", "reasoning_chunk", "thinking", "agent_thinking_chunk":
+	case "reasoning", "reasoning_chunk", "thinking", "agent_thinking_chunk", "agent_thought_chunk":
```

## 复现指南

1. 任意方式接入 opencode ACP 后端：

```toml
[[projects]]
name = "repro"

[projects.agent]
type = "acp"

[projects.agent.options]
work_dir = "/tmp/repro"
cmd = "opencode"        # v1.18.26，opencode.ai 官方安装
args = ["acp"]
```

2. 平台任选（QQBot/Feishu/Telegram 均可），`[log] level = "debug"`
3. 给 agent 发一个多步任务，例如：

```
在 /tmp/repro 目录里统计有几个文件，并读取任意一个文件的第一行，然后汇报
```

4. 观察 IM 收到的回复：开头出现 "Let me ..." / "The user asked me ..." 等英文独白（模型不同措辞不同）；DEBUG 日志可见 `agent_thought_chunk` 落入 `mapSessionUpdateFallback: unrecognized format`

## 修复后验证

- 同任务重跑：回复仅含正文（流程+结论），无独白
- DEBUG 日志：`agent_thought_chunk` 不再出现 unrecognized；`thinking_messages=true` 时它出现在 thinking 消息里（归类正确）
- 消息量：quiet 模式下多步任务从 10+ 条降为 1-4 条

## 兼容性说明

- 纯列表追加，不影响其他 agent（Gemini/Codex 等若使用其他事件名不受影响）
- ACP 规范未定义思维链标准事件名，本修复与现有 `agent_thinking_chunk` 识别共存
