#!/bin/bash
echo "=== 模拟开机空态：kill 容器内 opencode ==="
docker exec cc-remote sh -c 'pkill -f "opencode acp" 2>/dev/null; sleep 1'
sleep 2
echo "=== 确认空态（14096 应 000） ==="
curl -s -o /dev/null -w "14096=%{http_code}\n" --noproxy "*" --max-time 3 http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local
echo "=== 唤醒（webhook，模拟 ccwatcher EnsureServerAlive） ==="
curl -s -o /dev/null -w "wake=%{http_code}\n" --noproxy "*" --max-time 5 -X POST http://127.0.0.1:9111/hook \
  -H "Content-Type: application/json" -H "Authorization: Bearer cc-remote-selftest" \
  -d '{"session_key":"qqbot:2EB2DD390753D07C3AD3B16BA2667BDF","prompt":"wake-v14-test"}'
echo "=== 拉起后 14096 ==="
sleep 7
curl -s -o /dev/null -w "14096-after=%{http_code}\n" --noproxy "*" --max-time 3 http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local
