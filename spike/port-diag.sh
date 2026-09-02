#!/bin/bash
echo "=== 容器内全部 TCP 监听（16进制 local_address 转可读） ==="
docker exec cc-remote sh -c 'cat /proc/net/tcp | awk "NR>1 {print \$2}" | head -20'
echo "=== 用 python 查监听（更可靠） ==="
docker exec cc-remote python3 -c "
import socket
for port in [14096,4096,9111,9820,3000,8080,14097]:
    s=socket.socket(); s.settimeout(0.5)
    r=s.connect_ex(('127.0.0.1',port))
    print(port, 'OPEN' if r==0 else 'closed')
    s.close()
"
echo "=== opencode 进程 cmd ==="
docker top cc-remote -o pid,etime,cmd 2>/dev/null | grep -a opencode | grep -av grep
echo "=== opencode.log server/port 相关 ==="
docker exec cc-remote sh -c 'grep -a -i -e "server" -e "listen" -e "port" -e "14096" /root/.local/share/opencode/log/opencode.log 2>/dev/null | tail -8'
