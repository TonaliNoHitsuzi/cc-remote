# cc-remote 项目守则（新对话自动加载）

## 工作语言
- 所有输出使用中文，**包括思维链/思考过程（thinking）**——思考也用中文写（用户会在本地 TUI 实时围观你的思考流）。

## 本项目是什么
手机 QQ 远控本机 opencode agent 的部署工程。方案已定稿并经用户逐条确认（见 docs/01-方案定稿.md，平台变更史见其第 0 节）。**当前状态：M0–M2 已完成、生产容器上线、已开源（github.com/TonaliNoHitsuzi/cc-remote）**，上游补丁 PR #1789/#1790/#1791 提交中。剩余：M3 权限细化 / M5 Dashboard / M6 收尾。

## 开工前必读
README.md → docs/01-方案定稿.md → docs/02-开发计划.md。docs/03 是事实依据，拿不准时查。

## 硬性约束
- **版本锁定**：opencode v1.18.26；cc-connect **main@b39c11f 源码编译**（含 5 个本地补丁，见 patches/ 与 spike/优化-结论.md；升级需用户点头并重放补丁）
- **Docker-first**：生产跑 WSL2 Docker（Ubuntu-24.04，Docker 29），docker/ 目录为唯一生产配置来源
- **IO 红线**：AgentRoot 在 WSL 本地 `~/AgentRoot`，重 IO 不走 /mnt（9P 慢 18 倍；skills 目录挂 /mnt/d 属读取型，可接受）
- **安全红线**：`allow_from`/`admin_from` 白名单只放用户本人；14096 端口仅本机回环+密码（TUI attach 专用）；未来 Dashboard 启用时必须带鉴权；不暴露任何端口到公网
- **权限转发**：ask 类权限走 ACP → QQ 键盘按钮审批卡（兜底阶梯见 01 文档第 7 节，降级需用户确认）

## 已知 bug 与对策（实测状态）
- `/stop`：cc-connect #1776 在 main@b39c11f **未复现，已实测可用**（打断保留会话，取消空响应已被本地补丁静默）
- cc-connect 内建 cron 在 Docker 里找不到 daemon（#1719）→ 不用内建 cron，定时任务走宿主 systemd
- opencode ACP 空会话泄漏（#38064）→ 已部署每日 04:00 systemd timer 重启容器
- 每条消息冷启动的 run 模式已弃用，走 ACP 常驻进程

## LLM 认证
复用本机 opencode 登录凭证（`~/.local/share/opencode` 挂载进容器，容器与本地共享同一份），勿在容器里重新登录。
