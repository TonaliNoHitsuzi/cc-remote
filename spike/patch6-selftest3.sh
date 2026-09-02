#!/bin/bash
# 补丁⑥自测 v3：独立数据目录的 ACP 进程 + session/new 二连 + TUI attach 存活
cd ~/AgentRoot/cc-remote/spike
mkdir -p /tmp/oc-test-data /tmp/oc-test-config /tmp/oc-test-home
nohup node patch6-test.mjs new > /tmp/p6-acp.log 2>&1 &
ACP=$!
sleep 14
echo "=== ACP 侧 ==="; cat /tmp/p6-acp.log
kill -0 $ACP 2>/dev/null && echo "ACP node alive: YES" || echo "ACP node alive: NO"

nohup timeout 40 ./bin/opencode attach http://127.0.0.1:14097 -u opencode -p cc-remote-2026-local --dir ~/AgentRoot/cc-remote < /dev/null > /tmp/p6-tui.log 2>&1 &
TUI=$!
sleep 15
kill -0 $TUI 2>/dev/null && echo "TUI alive (after 2x session/new): YES" || echo "TUI alive: NO"
sleep 28
kill -0 $TUI 2>/dev/null && echo "TUI survived 40s: YES" || { wait $TUI; echo "TUI exit code: $?"; tail -2 /tmp/p6-tui.log | cut -c1-150; }
kill $ACP 2>/dev/null; pkill -f "port 14097" 2>/dev/null
echo "selftest done"
