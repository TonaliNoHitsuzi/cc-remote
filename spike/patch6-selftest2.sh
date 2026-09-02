#!/bin/bash
# 补丁⑥自测（容器内执行）：ACP 进程 session/new 二连 + TUI attach 存活观察
# ① 容器内起测试 ACP（14098）
docker exec -d cc-remote sh -c 'cd /home/zzy/AgentRoot/cc-remote && OPENCODE_CONFIG=/app/qq-opencode.json OPENCODE_SERVER_PASSWORD=cc-remote-2026-local /usr/local/bin/opencode acp --port 14098 --hostname 0.0.0.0 < /dev/null > /tmp/t-acp.log 2>&1'
sleep 8
docker exec cc-remote sh -c 'ps -o pid,cmd | grep 14098 | grep -v grep | head -2' || { echo "ACP-TEST-PROC-NOT-RUNNING"; docker exec cc-remote tail -3 /tmp/t-acp.log; exit 1; }

# ② WSL 侧 attach TUI（挂 40s）
cd ~/AgentRoot/cc-remote/spike
nohup timeout 40 ./bin/opencode attach http://127.0.0.1:14098 -u opencode -p cc-remote-2026-local --dir ~/AgentRoot/cc-remote < /dev/null > /tmp/t-tui.log 2>&1 &
TUI=$!
sleep 12
kill -0 $TUI 2>/dev/null && echo "TUI alive (phase1): YES" || echo "TUI alive (phase1): NO"

# ③ 用 node 直连 ACP（走容器映射端口 127.0.0.1:14098）再调 session/new —— 但 docker exec 的进程没有映射端口！
#    端口 14098 未在 compose 映射 —— 改为通过容器网络 IP 访问
CIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cc-remote)
echo "container ip: $CIP"

# ④ 在容器内跑 node？容器无 node。用 acp-client 思路：直接 bash jsonrpc 不现实。
#    改用：第二个 exec 连接 —— attach 本身就是客户端。用 opencode run --attach？
#    最简：再开一个 attach TUI（客户端），在 TUI 里 session 列表能看到几个会话。
echo "phase2: spawn second session via SDK on container ip"
node - <<'EOF' > /tmp/t-new.log 2>&1
const BIN="/home/zzy/AgentRoot/cc-remote/spike/bin/opencode";
EOF
sleep 28
kill -0 $TUI 2>/dev/null && echo "TUI survived 40s window: YES" || { wait $TUI; echo "TUI exit: $?"; }
docker exec cc-remote sh -c 'kill $(ps -o pid,cmd | grep 14098 | grep -v grep | awk "{print \$1}") 2>/dev/null; echo cleaned'
