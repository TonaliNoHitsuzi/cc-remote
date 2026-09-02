#!/bin/bash
echo "=== 容器内 curl 9111 ==="
docker exec cc-remote curl -s -o /dev/null -w "in-container-9111=%{http_code}\n" --max-time 3 http://127.0.0.1:9111/hook 2>&1 || echo "container curl failed"
echo "=== cc-connect webhook 相关日志（完整） ==="
docker logs cc-remote 2>&1 | grep -a -i -e webhook -e "listen" -e "bind" -e "9111" -e "address" | head -10
echo "=== cc-connect 进程还在? ==="
docker top cc-remote -o pid,etime,cmd 2>/dev/null | tail -2
echo "=== 容器内全部监听（hex） ==="
docker exec cc-remote sh -c 'cat /proc/net/tcp 2>/dev/null | awk "NR>1 {print \$2}" | head -10'
