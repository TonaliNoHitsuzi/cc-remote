#!/bin/bash
# 补丁⑥物理验证 v4：对容器真进程(14096) REST 建 session ×2 + TUI attach 存活
AUTH="opencode:cc-remote-2026-local"
B="http://127.0.0.1:14096"

echo "=== ① server 状态 ==="
code=$(curl -s -o /dev/null -w '%{http_code}' -u $AUTH $B/doc)
echo "GET /doc -> $code"
if [ "$code" != "200" ]; then echo "server not reachable (进程未起/懒启动)"; exit 1; fi

echo "=== ② 活进程上 REST 建 session（×2，等价补丁⑥ session/new） ==="
S1=$(curl -s -u $AUTH -X POST $B/session -H 'Content-Type: application/json' -d '{"directory":"/home/zzy/AgentRoot/cc-remote"}')
echo "session#1: $(echo $S1 | head -c 120)"
S2=$(curl -s -u $AUTH -X POST $B/session -H 'Content-Type: application/json' -d '{"directory":"/home/zzy/AgentRoot/cc-remote"}')
echo "session#2: $(echo $S2 | head -c 120)"

echo "=== ③ TUI attach 存活（40s 观察窗，期间 server 持续服务） ==="
cd ~/AgentRoot/cc-remote/spike
nohup timeout 40 ./bin/opencode attach $B -u $AUTH --dir ~/AgentRoot/cc-remote < /dev/null > /tmp/t4-tui.log 2>&1 &
TUI=$!
sleep 15
kill -0 $TUI 2>/dev/null && echo "TUI alive @15s: YES" || { echo "TUI alive @15s: NO"; wait $TUI; echo "exit=$?"; }
sleep 28
if kill -0 $TUI 2>/dev/null; then echo "TUI survived 40s: YES (结论：活进程多会话不杀 TUI)"; else wait $TUI; echo "TUI early exit: $?"; fi

echo "=== ④ 收尾：会话数确认 ==="
curl -s -u $AUTH $B/session 2>/dev/null | head -c 300
echo
echo "selftest-v4 done"
