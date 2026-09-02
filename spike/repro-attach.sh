#!/bin/bash
echo "=== 14096 稳定性（每2s查，10次） ==="
for i in $(seq 1 10); do
  c=$(curl -s -o /dev/null -w '%{http_code}' --noproxy '*' --max-time 2 http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local)
  p=$(docker top cc-remote -o cmd 2>/dev/null | grep -ac opencode)
  echo "t${i}: 14096=$c proc=$p"
  sleep 2
done
echo "=== attach 带 TTY（script 模拟）观察15s ==="
cd ~/AgentRoot/cc-remote/spike
timeout 15 script -qc "timeout 12 ./bin/opencode attach http://127.0.0.1:14096 -u opencode -p cc-remote-2026-local --dir ~/AgentRoot/cc-remote" /dev/null 2>&1 | grep -a -i -e error -e unable -e connect -e "20" | head -5
echo "=== 结果（有 error=闪退复现；无=稳定） ==="
