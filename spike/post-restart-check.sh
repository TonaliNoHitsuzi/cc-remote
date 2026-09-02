#!/bin/bash
echo "=== 容器状态 ==="
docker ps --format "{{.Names}} | {{.Status}}"
echo "=== cc-remote ready? ==="
sleep 5
docker logs cc-remote --since 2m 2>&1 | grep -a -c "platform ready"
echo "=== 宿主 14096 ==="
curl -s -o /dev/null -w "loopback=%{http_code}\n" --max-time 3 http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local
echo "=== 宿主 9111 ==="
curl -s -o /dev/null -w "hook=%{http_code}\n" --max-time 3 http://127.0.0.1:9111/hook
echo "=== 直连容器IP(转发测试) ==="
CIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cc-remote)
curl -s -o /dev/null -w "direct=%{http_code}\n" --max-time 3 http://$CIP:9111/hook
