# TODO：启动速度优化（2026-09-03 记录）

> 背景：开机后容器冷启动（WSL2+Docker+cc-remote 容器）约 **3 分钟**才就绪，用户托盘唤起 GUI 要等。这是环境固有耗时（无公网/IP依赖），非程序 bug。本文件列为未来计划。

## 现状（启动链时序）

```
开机 → 计划任务拉起 WSL (~5s) → dockerd 启动 → 容器 restart:always 拉起 (~1.5s) → cc-connect ready
→ opencode 进程随首条消息/唤醒 spawn (~2s)
```
瓶颈：Docker + WSL VM 冷启动（系统盘/VM 初始化），~3 分钟里大部分是 WSL/Docke 起 VM。

## 方向 A：包装成"带虚拟环境的完整应用"（脱离 Docker 直接跑）

- **目标**：cc-connect + opencode 打包成单个可执行/独立运行环境，不依赖 WSL Docker 容器（但仍需 WSL 或原生 Linux 内核——WSL 是内核依赖，难完全脱离；除非原生 Windows 二进制）
- **关键难点**：cc-connect 已有 Windows 版（GitHub release 有 windows-amd64）✓；opencode 有 Windows 版 ✓ → **其实可纯 Windows 跑**（不需 WSL）！但：
  - Windows 版绕开了 WSL，但**重 IO / git / 9P 目录结构**要适配（opencode 读 Windows 路径、ADENTS 工作区路径改写）
  - 凭证、skills 路径、watch/flag 桥（\\wsl$ 路径）全部要改
  - 9P 慢的问题消失（纯 Windows 本地读写）——反而更快
- **收益**：启动秒级（无 VM），可靠（无容器层转发）

## 方向 B：脱离虚拟机（纯 Windows 原生）

- Windows 装 cc-connect.exe + opencode.exe，工作区 D:\ 或 C:\，skills 本地路径
- 开机自启（Startup/服务）+ 系统代理不再蒙住 localhost（Windows 直管）
- 与现 WSL 方案的差异：工作区路径、凭证、watch 桥、TUI attach（Windows attach 到 Windows 进程端 server，同样可行）

## 决策点（需用户回头拍板）

1. **架构**：A（打包完整应用，仍 WSL）vs B（纯 Windows 原生脱离 WSL）——B 更彻底、更快，但改动面大（路径/桥/凭证/目录重构），且失去 WSL 的 Linux 环境（若 agent 任务依赖 Linux 工具则不适合）
2. **混合**：保留 WSL 容器跑 agent，但 Windows 侧原生跑"指挥层"？——复杂
3. **最小改动**：接受 3 分钟冷启动（日常不重启就没事；每日 04:00 定时重启也只需一次），只优化"开机常驻 Docker"（WSL 保持不关）——但用户希望快

## 下一步（未开工，等决策）

- [ ] 评估纯 Windows 原生跑 cc-connect+opencode 的可行性（opencode Windows 参数、工作区、凭证适配）——已确认两个都有 Windows 二进制，主要卡在"agent 任务是否依赖 Linux"
- [ ] 试跑：Windows 直接 cc-connect.exe（不 WSL）最小链路 + opencode + QQ 网关，看能否通
- [ ] 若能：写 Windows 版启动（ccwatcher 扩为 Windows 指挥 + 免 VM）
- [ ] 更新 docs/配置说明.md 的部署形态
