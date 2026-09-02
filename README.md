# cc-remote — QQ 机器人远控本机 opencode Agent

> 状态：**M0–M2 完成（2026-09-02），生产容器已上线**。手机 QQ 发指令 → WSL2 Docker 里的 cc-connect → opencode agent 执行 → 进度/结果/审批卡实时回 QQ。剩余：M3 权限细化收尾 / M5 Dashboard / M6 文档成套（见 docs/02-开发计划.md）。平台变更史：飞书 → 微信 ilink（实测否决：频控）→ QQ 机器人（采用，见 docs/01-方案定稿.md 第 0 节）。

## 生产运维速查

```bash
# 容器管理（WSL）
cd ~/AgentRoot/cc-remote/docker
docker compose logs -f cc-remote     # 日志
docker compose restart               # 重启
docker compose up -d --build         # 改配置/镜像后重建

# 关键挂载：凭证 ~/.local/share/opencode · 工作区 /home/zzy/AgentRoot ·
#   skills /mnt/d/Zzy的Skill工具包 · 提示词 docker/qq-style.md（改完 restart 生效）
# 每日 04:00 systemd timer 自动重启（治 ACP 泄漏）；ToDesk 围观状态桥由
#   Windows 侧 Scripts/watching-writer.ps1 提供（开机自启）
# 自启动链：Windows 登录 → 计划任务 WSL-Autostart-cc-remote 拉起 WSL →
#   systemd 起 docker → restart:always 起容器 → QQ 网关重连（全自动自愈）
# 空闲开销：cc-connect ~40MB；WSL vmmem ~1.4GB（含 Docker/searxng，非本项目大头）
# cc-connect 含 4 个本地补丁（思维链过滤等，见 spike/优化-结论.md），升级需重放
```

一句话：手机飞书发指令 → 家用电脑（WSL2 Docker 里的 cc-connect 网关）→ opencode agent 执行 → 进度 / 结果 / 权限审批卡实时回飞书。

## 文档索引

| 文档 | 内容 |
|---|---|
| `docs/01-方案定稿.md` | 最终架构、12 条共识、决策记录（ADR）、兜底阶梯——**已定项勿重新决策** |
| `docs/02-开发计划.md` | M0–M6 里程碑、验收标准、风险对策、版本锁定 |
| `docs/03-事实调研汇编.md` | cc-connect / opencode / 飞书平台关键事实快照 + issue 风险清单 |
| `docs/04-交接说明.md` | 新对话开工指南（环境核对、阅读顺序、注意事项） |
| `docs/research/` | 两份完整网络调研报告副本（原件在 `E:\网络调研\`） |

## 核心技术栈

cc-connect（Go 网关，15k★）· `opencode acp`（Agent Client Protocol）· 飞书自建应用（WS 长连接，免公网 IP）· WSL2 Docke
