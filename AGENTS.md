# cc-remote 项目守则（新对话自动加载）

## 本项目是什么
手机飞书远控本机 opencode agent 的部署工程。方案已定稿并经用户逐条确认（见 docs/01-方案定稿.md），**当前阶段：M0 未开始**。

## 开工前必读
README.md → docs/01-方案定稿.md → docs/02-开发计划.md。docs/03 是事实依据，拿不准时查。

## 硬性约束
- **版本锁定**：opencode v1.18.26；cc-connect 最新 release（须含 #1746 飞书修复）。不追新，升级需用户点头
- **Docker-first**：v1 直接在 WSL2 Docker 跑（Ubuntu-24.04，Docker 29 已装），Dockerfile + compose 放本目录
- **IO 红线**：AgentRoot 在 WSL 本地 `~/AgentRoot`，重 IO 不走 /mnt（9P 慢 18 倍）
- **安全红线**：`allow_from` 白名单只放用户本人；Dashboard :9820 必须带鉴权；不暴露任何端口到公网
- **权限转发**：ask 类权限必须走 ACP → 飞书审批卡（兜底阶梯见 01 文档第 7 节，降级需用户确认）

## 已知 bug 规避
- `/stop` 在 opencode 下会清会话（cc-connect #1776）→ 禁用，用 `/new`
- cc-connect 内建 cron 在 Docker 里找不到 daemon（#1719）→ 不用，容器重启走宿主 systemd time
- opencode ACP 空会话泄漏（opencode #38064）→ 每日定时重启容器
- 每条消息冷启动的 run 模式已弃用，走 ACP 常驻进程

## LLM 认证
复用本机 opencode 登录凭证（`~/.config/opencode` + `~/.local/share/opencode` 挂载进容器），勿在容器里重新登录。
