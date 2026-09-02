#!/bin/bash
echo "=== 容器 IP（inspect） ==="
docker inspect cc-remote --format '{{json .NetworkSettings.Networks}}' 2>&1 | head -c 400
echo ""
echo "=== 容器内监听（/proc/net/tcp 的 3710/2393） ==="
docker exec cc-remote sh -c 'cat /proc/net/tcp 2>/dev/null | awk "NR>1 {print \$2}" | grep -i -e 3710 -e 2393'
echo "(空=容器内没监听这两个端口)"
echo "=== 宿主网桥 ==="
ip a 2>/dev/null | grep -E "br-|docker0" | head -4
echo "=== docker-proxy 现在 ==="
ps aux | grep -a "[d]ocker-proxy" | head -4
