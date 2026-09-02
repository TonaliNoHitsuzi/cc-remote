#!/bin/bash
echo "=== 容器 DNS ==="
docker exec cc-remote sh -c 'cat /etc/resolv.conf'
echo "=== 容器外网连通 ==="
docker exec cc-remote sh -c 'curl -s -o /dev/null -w "models.opencode.ai=%{http_code} time=%{time_total}s\n" --max-time 8 https://models.opencode.ai/api.json 2>&1 || echo "curl failed"'
docker exec cc-remote sh -c 'curl -s -o /dev/null -w "baidu=%{http_code}\n" --max-time 6 https://www.baidu.com 2>&1 || echo "baidu failed"'
echo "=== 宿主 WSL 外网 ==="
curl -s -o /dev/null -w "host-models=%{http_code}\n" --max-time 6 https://models.opencode.ai/api.json 2>&1 || echo "host failed"
echo "=== docker 网络 ==="
docker network ls
docker inspect cc-remote --format "{{.NetworkSettings.Networks}}"
