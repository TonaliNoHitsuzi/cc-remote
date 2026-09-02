# cc-remote — 飞书远控本机 opencode Agent

> 状态：**方案定稿（2026-09-02），未开工**。下一步从 `docs/02-开发计划.md` 的 M0 开始。

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
