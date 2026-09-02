# cc-remote — 手机 QQ 远控本机 opencode Agent

手机 QQ 发指令 → 家用电脑 WSL2 Docker 里的 [cc-connect](https://github.com/chenhg5/cc-connect) → [opencode](https://opencode.ai) agent 执行 → 结果/进度/**按钮式权限审批**实时回 QQ。

```
┌─ 手机 QQ（零新 app） ──────────────────────────────┐
│  聊天下指令 · 看流式结果 · 权限卡【允许/拒绝】      │
│  收发文件 · /gui 唤醒电脑端对话界面 · 围观感知      │
└────────── QQ 官方 WS 网关（出站，免公网 IP）────────┘
                            │
┌─ 家用电脑 · WSL2 Docker ───────────────────────────┐
│  cc-connect 容器（restart:always + 每日定时重启）  │
│   └─ ACP ⇄ opencode v1.18.26（GLM-5.3，凭证复用） │
│  工作区 ~/AgentRoot · Windows 托盘看门狗 ccwatcher │
└────────────────────────────────────────────────────┘
```

## 特性（全部实测）

- **按钮权限审批**：agent 跨目录/危险操作 → QQ 键盘卡【允许/拒绝/允许所有】，点击直达 agent（`允许所有`= 会话级自动批准）
- **极致省消息**：quiet 模式 turn 级消息入栈 + 思维链传输层过滤，多步任务 **1-4 条消息**（优化前 15-20 条），远离频控焦虑
- **真实上下文足迹**：每条回复尾部分行显示 `模型 / 上下文 量+百分比 / 缓存命中`（opencode 实时上报，非估算）
- **文件路由**：agent 生成的文件自动发回 QQ；你发的文件/图片 agent 直接读
- **对话 GUI**：托盘菜单 / QQ 指令 `/gui` / AI 自然语言三入口，一键在电脑弹出 opencode TUI 并**直达 QQ 正在进行的会话**
- **围观感知**：ToDesk 远控围观时 AI 可检测你在看（浮窗自动收起 + 状态桥）
- **全链自愈**：Windows 登录 → WSL → Docker → 容器 → QQ 网关重连，全程零人工
- **单对话域**：默认不分裂会话，仅显式 `/new` 才开新（手机 `/list` `/switch` 随时管理）
- **skill 生态**：agent 可路由你的 Agent Skills（如牧羊人注册库）

## 快速开始

### 前置

- Windows 10/11 + WSL2（Ubuntu 24.04，启用 systemd + Docker）
- 本机已登录 opencode（凭证在 `~/.local/share/opencode/auth.json`）
- 一个 QQ 号（[申请机器人](docs/QQ机器人申请指南.md)，约 20 分钟）

### 步骤

```bash
# 1. 取两个二进制（见下方"构建产物"）放到 spike/bin/
#    cc-connect（源码编译，含 5 个补丁）+ opencode v1.18.26（官方 linux-x64）

# 2. 凭证
cd docker && cp .env.example .env   # 填 QQ_APP_ID / QQ_APP_SECRET

# 3. 构建并启动
docker compose up -d --build
docker logs cc-remote               # 等待 "qqbot: gateway READY"

# 4. 手机 QQ 给机器人发消息，首次配置白名单
/whoami                              # 拿 openid 填入 .env 的 QQ_ALLOW_FROM
docker compose restart
```

完整配置项说明见 [docs/配置说明.md](docs/配置说明.md)。

### 构建产物

| 二进制 | 来源 |
|---|---|
| `spike/bin/cc-connect-dev` | cc-connect main@b39c11f 源码编译（`-tags no_web`），含 5 个本地补丁（见下） |
| `spike/bin/opencode` | [opencode v1.18.26](https://github.com/sst/opencode/releases/tag/v1.18.26) 官方 `opencode-linux-x64.tar.gz` |

## 本地补丁（上游 PR 素材）

| # | 位置 | 内容 |
|---|---|---|
| 1 | `agent/acp/mapping.go` | opencode 的 `agent_thought_chunk` 归类 EventThinking（原名不匹配被当正文泄漏思维链） |
| 2 | `core/engine.go` | 有原生按钮的平台跳过"已允许"冗余确认（点击自带反馈） |
| 3 | `core/engine.go` | ACP 优雅取消增加 `turnCancelled` 标志，打断后空 turn 不发"(空响应)" |
| 4 | （随 #3） | 打断空响应复用 NO_REPLY 静默通道 |
| 5 | `agent/acp/session.go` + `core/engine.go` | 实现 ContextUsageReporter（usage_update/prompt response 真实数据）+ 分行标签式 footer |

复现方式见 [spike/优化-结论.md](spike/优化-结论.md)；均待提交上游。

## QQ 命令速查

| 常用 | 说明 |
|---|---|
| `/gui` | 电脑弹出 opencode 对话界面（直达当前会话） |
| `/new` `/list` `/switch N` | 会话管理（默认永不自动分裂） |
| `/compress` | 手动压缩上下文（footer 百分比过高时用） |
| `/stop` | 打断当前执行（会话保留，发消息即续） |
| `/whoami` | 获取 openid（部署后填白名单用） |

## 安全

- **白名单**：`allow_from` 只放行你自己（openid 经 `/whoami` 获取）
- **零端口暴露**：v1 容器不映射任何端口；QQ 通道为出站 WS 长连接
- **凭证隔离**：AppSecret/openid 走 `.env`（已 gitignore），仓库仅模板
- **权限模型**：opencode 原生 permission 三态（AgentRoot 内 allow / 跨目录 ask→QQ 卡 / 危险 deny）
- 免责：本工具允许远程触发本机 AI 执行命令，请自行评估风险、保管好 QQ 账号与机器人凭证

## 目录结构

```
docker/          生产：Dockerfile、compose、config.toml、qq-style.md（输出规范）、assets（图标）
docs/            方案定稿、开发计划、QQ 申请指南、配置说明、交接说明
spike/           验证期产物：ACP 握手脚本、5 份实测结论文档、辅助脚本
```

## 致谢

- [chenhg5/cc-connect](https://github.com/chenhg5/cc-connect) — 多平台 agent 网关（本项目核心依赖 + 补丁基线）
- [sst/opencode](https://github.com/sst/opencode) — AI coding agent
- 本项目是对两者集成体验的实测与增强，非官方项目

## License

[MIT](LICENSE)
