#!/bin/bash
echo "=== 宿主 9111（webhook） ==="
curl -s -o /dev/null -w "hook=%{http_code}\n" --max-time 3 http://127.0.0.1:9111/hook
echo "=== 容器内 9111 ==="
docker exec cc-remote sh -c 'cat /proc/net/tcp 2>/dev/null | awk "NR>1 {print \$2}" | grep -i 2393 | head -1'
echo "(空=容器内无9111监听)"
echo "=== 唤醒进程 ---"
curl -s -o /dev/null -w "wake=%{http_code}\n" --max-time 5 -X POST http://127.0.0.1:9111/hook \
  -H "Content-Type: application/json" -H "Authorization: Bearer cc-remote-selftest" \
  -d '{"session_key":"qqbot:2EB2DD390753D07C3AD3B16BA2667BDF","prompt":"wake-test"}'
sleep 8
echo "=== 进程 ==="
docker top cc-remote -o pid,cmd 2>/dev/null | grep -a opencode | grep -av grep | head -1
echo "=== 宿主 14096 ==="
curl -s -o /dev/null -w "loopback14096=%{http_code}\n" --max-time 4 http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local
