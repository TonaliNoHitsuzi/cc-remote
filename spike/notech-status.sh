#!/bin/bash
echo "=== 容器状态 ==="
docker ps --format "{{.Names}} | {{.Status}}" | head -4
echo "=== ready ==="
docker logs cc-remote --since 3m 2>&1 | grep -a -c "platform ready"
echo "=== 14096 端口（进程空应 000，走代理关着的宿主 --noproxy 测） ==="
curl -s -o /dev/null -w "14096=%{http_code}\n" --noproxy "*" --max-time 3 http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local
echo "=== opencode 进程 ==="
docker top cc-remote -o cmd 2>/dev/null | grep -a opencode | grep -av grep | head -1
echo "(空=未拉活，属开机空态正常)"
