#!/bin/bash
echo "=== 容器 ready ==="
docker logs cc-remote --since 2m 2>&1 | grep -a -c "platform ready"
echo "=== 容器状态 ==="
docker ps --format "{{.Names}} | {{.Status}}" | head -3
echo "=== 14096 进程 ==="
docker top cc-remote -o cmd 2>/dev/null | grep -a opencode | grep -av grep | head -1
echo "(空=未拉活)"
echo "=== 手动 WSL curl 唤醒一次（看真实响应） ==="
curl -s -o /dev/null -w "wake=%{http_code}\n" --noproxy "*" --max-time 5 -X POST http://127.0.0.1:9111/hook \
  -H "Content-Type: application/json" -H "Authorization: Bearer cc-remote-selftest" \
  -d '{"session_key":"qqbot:2EB2DD390753D07C3AD3B16BA2667BDF","prompt":"wake-manual-now"}'
sleep 7
echo "=== 拉皮后 14096 ==="
curl -s -o /dev/null -w "14096=%{http_code}\n" --noproxy "*" --max-time 3 http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local
