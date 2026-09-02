#!/bin/bash
# 宿主侧验证：14096/9111 映射 + webhook 唤醒链路
echo "=== 14096 (opencode server) ==="
curl -s -o /dev/null -w "14096/doc=%{http_code}\n" http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local
echo "=== 9111 (webhook) 宿主映射 ==="
curl -s -o /dev/null -w "9111/hook=%{http_code}\n" -X POST http://127.0.0.1:9111/hook \
  -H "Content-Type: application/json" -H "Authorization: Bearer cc-remote-selftest" \
  -d '{"session_key":"qqbot:2EB2DD390753D07C3AD3B16BA2667BDF","prompt":"host-wake"}'
echo "=== 唤醒后进程 ==="
sleep 6
docker top cc-remote -o pid,cmd | grep -a opencode | grep -av grep | head -1
