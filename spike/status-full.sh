#!/bin/bash
echo "=== 容器状态/时长 ==="
docker ps --format "{{.Names}} | {{.Status}}"
echo "=== cc-connect 进程 ==="
docker top cc-remote -o pid,etime,cmd 2>/dev/null | tail -3
echo "=== 容器内 9111/14096 ==="
docker exec cc-remote sh -c '(echo > /dev/tcp/127.0.0.1/9111) 2>/dev/null && echo 9111-OPEN || echo 9111-CLOSED; (echo > /dev/tcp/127.0.0.1/14096) 2>/dev/null && echo 14096-OPEN || echo 14096-CLOSED'
echo "=== 宿主侧探测 ==="
(echo > /dev/tcp/127.0.0.1/9111) 2>/dev/null && echo host-9111-OPEN || echo host-9111-CLOSED
(echo > /dev/tcp/127.0.0.1/14096) 2>/dev/null && echo host-14096-OPEN || echo host-14096-CLOSED
echo "=== 最近日志（含错误） ==="
docker logs cc-remote --since 10m 2>&1 | grep -a -i -e error -e busy -e ready -e restart | tail -6
