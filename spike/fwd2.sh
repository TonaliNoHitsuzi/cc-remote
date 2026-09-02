#!/bin/bash
echo "=== tcp6 监听（9111=00002393 14096=00003700） ==="
docker exec cc-remote sh -c 'cat /proc/net/tcp6 2>/dev/null | awk "NR>1 {print \$2}" | grep -i -e 2393 -e 3700'
echo "(空=tcp6 无)"
echo "=== tcp 监听全部 ==="
docker exec cc-remote sh -c 'cat /proc/net/tcp 2>/dev/null | awk "NR>1 {print \$2}"'
echo "=== 宿主 ss 9111/14096 ==="
ss -tlnp 2>/dev/null | grep -e 9111 -e 14096 || echo "宿主无监听(但docker-proxy在)"
echo "=== 宿主 curl 9111 verbose ==="
curl -sv --max-time 4 http://127.0.0.1:9111/hook 2>&1 | grep -E "Connected|Connection|refused|timed" | head -3
