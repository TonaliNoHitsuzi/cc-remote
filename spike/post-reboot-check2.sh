#!/bin/bash
echo "=== 容器 ready ==="
docker logs cc-remote --since 5m 2>&1 | grep -a -c "platform ready"
echo "=== 14096 进程/端口 ==="
docker top cc-remote -o cmd 2>/dev/null | grep -a opencode | grep -av grep | head -1
curl -s -o /dev/null -w "14096=%{http_code}\n" --noproxy "*" --max-time 3 http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local
echo "=== 唤醒(若进程空则拉起) ==="
if [ -z "$(docker top cc-remote -o cmd 2>/dev/null | grep -a opencode | grep -av grep)" ]; then
  curl -s -o /dev/null -w "wake=%{http_code}\n" --noproxy "*" --max-time 5 -X POST http://127.0.0.1:9111/hook \
    -H "Content-Type: application/json" -H "Authorization: Bearer cc-remote-selftest" \
    -d '{"session_key":"qqbot:2EB2DD390753D07C3AD3B16BA2667BDF","prompt":"wake-post-reboot"}'
  sleep 6
fi
echo "=== 14096 复查 + 进程 ==="
curl -s -o /dev/null -w "14096-again=%{http_code}\n" --noproxy "*" --max-time 3 http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local
docker top cc-remote -o cmd 2>/dev/null | grep -a opencode | grep -av grep | head -1
