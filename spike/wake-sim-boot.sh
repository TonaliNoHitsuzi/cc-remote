#!/bin/bash
# 模拟真实开机:容器全新 -> 进程空 -> webhook 唤醒 -> spawn
echo "=== 重启容器(clean 状态, 模拟开机) ==="
docker restart cc-remote 2>&1 | tail -1
sleep 12
echo "=== ready? ==="
docker logs cc-remote --since 15s 2>&1 | grep -a -c "platform ready"
echo "=== 空态 14096 ==="
curl -s -o /dev/null -w "14096=%{http_code}\n" --noproxy "*" --max-time 3 http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local
echo "=== webhook 唤醒 ==="
curl -s -o /dev/null -w "wake=%{http_code}\n" --noproxy "*" --max-time 5 -X POST http://127.0.0.1:9111/hook \
  -H "Content-Type: application/json" -H "Authorization: Bearer cc-remote-selftest" \
  -d '{"session_key":"qqbot:2EB2DD390753D07C3AD3B16BA2667BDF","prompt":"wake-sim-boot"}'
sleep 8
echo "=== spawn 后 14096 ==="
curl -s -o /dev/null -w "14096-after=%{http_code}\n" --noproxy "*" --max-time 3 http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local
echo "=== cc-connect 处理 ==="
docker logs cc-remote --since 30s 2>&1 | grep -a -e "webhook" -e "spawned" -e busy | tail -4
