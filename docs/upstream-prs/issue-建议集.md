# Issue 建议集（不成 PR 的观察，供 upstream 参考）

> 以下为部署实测中发现、但不适合以当前形态直接提 PR 的事项。可按需整理成 issue。

## 1. weixin(ilink) push 预算的部署期提示

**观察**：微信 ilink 平台的 push 路径预算（24h 窗口 ~4-5 条，engine 侧 `push_path_budget_exceeded`）对首次部署者非常反直觉：机器人"连上了、能收消息"，但回复静默丢失（reply 走 push 路径时）。

**建议**：README 或 docs/weixin.md 增加显眼说明：ilink 通道仅适合低频通知场景；当出现回复丢失时优先排查 push budget（日志关键字 `push_path_budget_exceeded`）。相关 issue #1716/#1742 已有讨论，但文档层缺一个部署者视角的预警。

## 2. ACP 后端的 `/gui` 类宿主联动场景（feature idea）

**场景**：IM 远控场景中，用户常需要在电脑端弹出 agent 的本地 TUI 并**直达 IM 正在进行的会话**（cc-connect data/sessions 里有 AgentSessionID 映射，但无对外 API）。

**建议**：提供一个 CLI 子命令（如 `cc-connect session current --project X --json`），输出当前活跃会话的 agent session id，方便外部工具（托盘程序、桌面快捷方式）实现"打开 GUI 即续聊"。当前我们通过直接解析 `data/sessions/*.json` 实现，属于脆弱的内部格式依赖。

## 3. `reset_on_idle_mins` 默认值对"单对话域"用户的心智负担

**观察**：默认 30 分钟空闲自动新会话，对长周期个人助理型用法（用户希望"永远一个对话域，显式 /new 才换"）会造成"为什么上下文忘了"的困惑。日志有 WARN 提示，但用户通常不会看日志。

**建议**：`/status` 或首次空闲重置时，向 IM 侧发一条轻量提示（"已因空闲开启新会话，/list 可切回"），或 README 补充该默认值的说明与关闭方法。

## 4. QQBot 键盘按钮依赖 markdown_support 的文档缺口

**观察**：`markdown_support = false` 时，权限卡仍会发出（`SendWithButtons` 走 msg_type=0 + keyboard 字段），QQ 网关**静默忽略** keyboard——用户看到纯文本权限提示 + 文字指令兜底，功能可用但按钮"消失"，极难自行定位。

**建议**：docs/qqbot.md 增加说明："要渲染键盘按钮必须 `markdown_support = true`（msg_type=2 + keyboard）"；或在 false 时打一条 WARN 日志提示按钮不会渲染。
