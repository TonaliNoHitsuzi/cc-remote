# TODO：下一阶段——进程生命周期管理 + 脱离 WSL 虚拟化（2026-09-03 立项，未开工）

> 背景：v1（WSL2 Docker 容器 + 手搓 ccwatcher C# 看门狗）已稳定运行，但暴露两个结构性问题：
> ① 进程生命周期（自愈/重试/优雅关闭/状态机）全靠手搓，Windows 生态本有成熟方案，摸索浪费了大量时间；
> ② 开机到可用 ~3 分钟（WSL VM + Docker 冷启动是主要瓶颈），体验差。
> 本文件是下一阶段的任务书，做的时候从这里开始。

---

## 任务 1：进程生命周期管理——用现成的，别再手搓

### 痛点清单（v1 手搓踩过的坑，换方案时要全覆盖）

| v1 手搓实现 | 对应的标准能力 |
|---|---|
| v18 灰图标→就绪→亮 状态机 + InitLoop 自检 | 服务健康检查（healthcheck）+ 依赖就绪等待 |
| wake 重试 12×5s、busy→docker restart 升级 | 崩溃恢复策略（restart policy + backoff） |
| FullShutdown 杀 TUI + 停容器 | 进程组/作业对象管理（父退子收） |
| 单实例 Mutex、日志手写文件 | 服务框架标配 |
| 开机 Startup 快捷方式 + 计划任务混用 | 服务开机自启（延迟启动/依赖顺序） |

### 候选方案（按推荐顺序，开工前调研对比一轮）

1. **WinSW**（Windows Service Wrapper，单 exe + xml 配置）
   - 把任意 exe 包装成 Windows 服务：开机自启、崩溃自动重启、日志重定向、`<onabort>` 等失败动作
   - 适合包装 cc-connect.exe（Windows 版）和 opencode 相关进程
   - MIT 协议，单文件分发
2. **NSSM**（Non-Sucking Service Manager）
   - 老牌，功能类似 WinSW；注意 license（公有领域 vs WinSW MIT，两者都可用）
3. **原生 Windows Service**（sc.exe + 服务实现）
   - cc-connect 是 Go 程序，可考虑 kardianos/service 库原生支持服务化（需改代码/提上游 issue）
4. **Task Scheduler 高级用法**：触发器（开机/登录/事件）、失败重试、执行时限——v1 已用了一半，可深挖但不如服务化正规

### 任务分解

- [ ] 调研 WinSW vs NSSM vs 原生服务，选定包装方案（决策点：日志、重启策略、优雅停止信号支持 SIGTERM 吗）
- [ ] cc-connect Windows 二进制获取：GitHub release 有 windows-amd64（**注意**：需含我们的 5 个补丁 → 本地交叉编译 `GOOS=windows GOARCH=amd64`，`scripts/build-cc-connect.sh` 加参数）
- [ ] 定义服务拓扑：谁包谁（cc-connect 服务化；opencode 由 cc-connect spawn 不需要单独服务；ccwatcher 保留托盘交互不服务化）
- [ ] ccwatcher 瘦身：删掉 InitLoop 自愈/FullShutdown 里的进程管理逻辑（交给服务框架），只留托盘 UI + 浮窗收起 + 围观桥 + attach
- [ ] 验收：杀进程自动重启 ≤5s；关机优雅退出；开机免登录可用（服务模式）

---

## 任务 2：启动速度——取消 WSL 虚拟化，服务独立启用

### 现状瓶颈（实测）

```
开机 → WSL VM 冷启动 (~1-2min) → dockerd → 容器 (~1.5s) → cc-connect ready → 唤醒 opencode (~3s)
```
3 分钟里 **95% 是 WSL VM + Docker**。去掉这两层，纯 Windows 进程启动是秒级。

### 核心方案：纯 Windows 原生跑 cc-connect + opencode

两个主件都有 Windows 二进制（已确认）：
- cc-connect：release 含 windows-amd64.zip ✓
- opencode：v1.18.26 官方有 Windows 版 ✓（**注意**：当前锁的 linux-x64 是容器用的；Windows 版需另验 ACP 行为，M0 结论里的协议细节应通用但要复测）

### 迁移适配清单（从 WSL 容器到 Windows 原生）

| 项 | 现状（WSL/容器） | Windows 原生目标 |
|---|---|---|
| 工作区 | ~/AgentRoot（WSL ext4） | `D:\AgentRoot` 或 `C:\AgentRoot`（NTFS 原生，无 9P 问题） |
| opencode 凭证 | 容器挂载 WSL ~/.local/share/opencode | Windows `%USERPROFILE%\.local\share\opencode`（**本机已有一套**，直接复用） |
| skills | /mnt/d/Zzy的Skill工具包（9P 挂载） | `D:\Zzy的Skill工具包`（原生路径，更快） |
| qq-style/qq-opencode.json | 容器 /app 挂载 | Windows 路径 + OPENCODE_CONFIG 指向 |
| 14096 attach | 容器映射 127.0.0.1:14096 | 原生进程直接监听 127.0.0.1（无 docker-proxy 层，**连接层少一跳**） |
| webhook 9111 唤醒 | 同上 | 同上 |
| watching/gui.flag 桥 | \\wsl$ UNC 路径（慢且断连风险） | 本地文件（直接快速） |
| 密码/代理 | env -u（bun no_proxy bug 绕过） | 同样需要；Windows 侧 curl.exe --noproxy 经验可复用 |
| AGENTS.md 服务卡 | 容器读挂载 | Windows 工作区根 |
| 环境差异 | Linux 工具链（bash/git/ssh 等 agent 任务可用） | **风险点**：agent 执行的任务若依赖 Linux 工具（apt 装的、bash 脚本、路径习惯），Windows 侧要有等价物或接受降级。需盘点 AGENTS.md 里的能力地图并逐项核对 |

### 任务分解

- [ ] **决策点 A**：工作区迁哪里（D 盘现有项目多的话 → D:\AgentRoot）；是否保留 WSL 版做备份/双轨
- [ ] **风险盘点**：列出 agent 常用能力在 Windows 的可用性（git/bash(git-bash)/python/node/skills 里的 python 脚本/路径写法），决定 AGENTS.md 改写幅度
- [ ] Windows 版 cc-connect 补丁编译：`GOOS=windows` 交叉编译（补丁同一套源码直接编）
- [ ] Windows 版 opencode v1.18.26 下载 + ACP 快速回归（复用 spike/acp-client.mjs，cmd 换 Windows 路径）
- [ ] 最小链路试跑：cc-connect.exe（Windows）+ opencode.exe（Windows）+ QQ 网关连通 + 按钮审批往返
- [ ] 服务化落地（衔接任务 1：WinSW/NSSM 包装 cc-connect，开机秒级就绪）
- [ ] TUI attach 适配：wt 直接跑 Windows opencode attach 127.0.0.1:14096（无 wsl 层，更快）
- [ ] ccwatcher 简化：桥文件本地化、唤醒/探测逻辑保留但去掉 docker 依赖
- [ ] 文件路由回归：cc-connect send --file 在 Windows 路径下的行为
- [ ] 验收：**开机到 QQ 机器人可用 ≤30s**（对比 v1 的 ~3min）；托盘 attach 秒开
- [ ] 收尾：docs/配置说明.md 重写部署形态；v1 WSL 方案归档为灾备

### 决策点汇总（开工前需拍板）

1. 工作区根路径（D:\AgentRoot?）
2. WSL 版去留（灾备保留 / 直接废弃）
3. 服务包装选型（任务 1 的调研结论）
4. agent 任务的 Linux 依赖降级是否可接受（若不可接受，考虑 Windows 主 + WSL 按需启的双轨）

---

## 历史包袱提醒（迁移时别忘）

- `docker/config.toml` 里的配置语义（display quiet / 语言 / admin_from / reset_on_idle 等）在 Windows 原生版要逐项平移
- webhook token、OPENCODE_SERVER_PASSWORD、QQ 凭证三件套走 .env 的惯例保持
- 每日 04:00 重启 timer 的教训：**不要 Persistent=true 补跑**（撞冷启动造成服务中断，2026-09-03 实证）
- 上游 4 个 PR（#1789/1790/1791 + 待提的补丁⑥⑦）合并后可减少本地补丁负担
