#!/bin/bash
CIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cc-remote)
echo "container IP=$CIP"
echo "=== 宿主直连容器IP:14096 ==="
curl -s -o /dev/null -w "direct=%{http_code}\n" --max-time 5 http://$CIP:14096/doc -u opencode:cc-remote-2026-local
echo "=== 宿主 127.0.0.1:14096 ==="
curl -s -o /dev/null -w "loopback=%{http_code}\n" --max-time 5 http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local
echo "=== docker-proxy 进程 ==="
ps aux | grep -a "[d]ocker-proxy.*14096" | head -2
echo "=== 14096 相关监听(宿主) ==="
ss -tlnp 2>/dev/null | grep -e 14096 -e 9111
echo "=== WSL 到容器网关路由 ==="
ip route 2>/dev/null | head -5
