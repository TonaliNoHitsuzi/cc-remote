#!/bin/bash
# 容器内 webhook 自测 + 日志取证
echo "=== 容器内 curl webhook ==="
docker exec cc-remote curl -s -o /dev/null -w "in-container hook=%{http_code}\n" http://127.0.0.1:9111/hook 2>&1 || echo "curl failed"
echo "=== 容器内 curl 14096 ==="
docker exec cc-remote curl -s -o /dev/null -w "in-container opencode=%{http_code}\n" http://127.0.0.1:14096/doc 2>&1 || echo "curl failed"
echo "=== 日志 webhook/error 相关 ==="
docker logs cc-remote 2>&1 | grep -a -i -e "webhook" -e "9111" -e "listen" -e "bind" | head -6
echo "=== cc-connect 是否还在 ===="
docker top cc-remote -o pid,etime,cmd | tail -2
