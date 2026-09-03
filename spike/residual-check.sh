#!/bin/bash
echo "=== 容器（应无 cc-remote） ==="
docker ps -a --format "{{.Names}} | {{.Status}}" | head -6
echo "=== 容器内进程（cc-remote 若在） ==="
docker top cc-remote -o pid,cmd 2>/dev/null | tail -4 || echo "(容器不在)"
echo "=== WSL 残留 opencode/cc-connect 进程 ==="
ps aux | grep -a -i -e opencode -e cc-connect | grep -av grep | head -5
echo "(空=无残留)"
echo "=== 端口残留（14096/9111） ==="
ss -tlnp 2>/dev/null | grep -e 14096 -e 9111 || echo "(无监听)"
