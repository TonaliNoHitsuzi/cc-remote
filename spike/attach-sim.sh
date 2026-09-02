#!/bin/bash
# 完整模拟 ccwatcher attach 流程：探测→(若空)webhook→等端口→attach
is_alive() { curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local 2>/dev/null; }

code=$(is_alive)
echo "initial 14096: $code"
if [ "$code" != "200" ]; then
  echo "-> wake via hook"
  curl -s -o /dev/null -X POST http://127.0.0.1:9111/hook -H "Content-Type: application/json" -H "Authorization: Bearer cc-remote-selftest" \
    -d '{"session_key":"qqbot:2EB2DD390753D07C3AD3B16BA2667BDF","prompt":"wake-for-tui"}'
  for i in $(seq 1 12); do
    sleep 2
    code=$(is_alive)
    [ "$code" = "200" ] && { echo "port ready after ${i}x2s"; break; }
  done
fi
echo "final 14096: $code"
# attach 观察 20s
cd ~/AgentRoot/cc-remote/spike
nohup timeout 20 ./bin/opencode attach http://127.0.0.1:14096 -u opencode -p cc-remote-2026-local --dir ~/AgentRoot/cc-remote < /dev/null > /tmp/at.log 2>&1 &
T=$!
sleep 14
kill -0 $T 2>/dev/null && echo "TUI attach alive: YES" || { wait $T; echo "TUI attach exit: $? (0=正常随timeout结束)"; }
kill $T 2>/dev/null
