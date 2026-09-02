#!/bin/bash
echo "=== 容器状态 ==="
docker ps --format "{{.Names}} | {{.Status}}" | head -3
echo "=== 容器 ready ==="
docker logs cc-remote --since 2m 2>&1 | grep -a -c "platform ready"
echo "=== 容器内 9111 监听 ==="
docker exec cc-remote sh -c 'cat /proc/net/tcp /proc/net/tcp6 2>/dev/null | awk "NR>1 {print \$2}" | grep -i -e 2393 | head -1'
echo "(空=容器内无9111)"
echo "=== WSL 侧 127.0.0.1:9111 TCP 探测 ==="
(echo > /dev/tcp/127.0.0.1/9111) 2>/dev/null && echo "WSL 9111 OPEN" || echo "WSL 9111 CLOSED"
echo "=== ccwatcher 进程 ==="
ps aux | grep -a "[c]cwatcher" | head -1 || echo "(查Windows进程另行)"
