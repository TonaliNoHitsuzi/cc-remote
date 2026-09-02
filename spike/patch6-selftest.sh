#!/bin/bash
# 补丁⑥自测：本地 ACP 进程 + session/new + TUI attach 存活验证
cd ~/AgentRoot/cc-remote/spike
# ① 起 ACP 测试进程（14097，带 session/new 二连）
nohup node patch6-test.mjs new > /tmp/p6-acp.log 2>&1 &
ACP_PID=$!
sleep 12
echo "=== ACP 侧 ==="; cat /tmp/p6-acp.log

# ② attach TUI（挂 45 秒观察），--continue 落最新会话
nohup timeout 45 ./bin/opencode attach http://127.0.0.1:14097 -u opencode -p cc-remote-2026-local --dir ~/AgentRoot/cc-remote < /dev/null > /tmp/p6-tui.log 2>&1 &
TUI_PID=$!
sleep 15
if kill -0 $TUI_PID 2>/dev/null; then echo "TUI alive after attach + session/new: YES"; else echo "TUI alive: NO (exited)"; fi

# ③ 再次 session/new 已在①里二连完成；再确认 ACP 进程仍活
if kill -0 $ACP_PID 2>/dev/null; then echo "ACP process alive: YES"; else echo "ACP alive: NO"; fi
sleep 35
echo "=== TUI 45s 后（timeout 杀前检查） ==="
if kill -0 $TUI_PID 2>/dev/null; then echo "TUI survived full window: YES"; else wait $TUI_PID; echo "TUI exit code: $?"; fi
kill $ACP_PID 2>/dev/null
