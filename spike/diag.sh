#!/bin/bash
# 重启后诊断：进程/端口/webhook/拉活
echo "=== 1. opencode 进程 ==="
docker top cc-remote -o pid,etime,cmd 2>/dev/null | grep -a opencode | grep -av grep | head -1
echo "(空=未拉活)"
echo "=== 2. 14096 端口 ==="
curl -s -o /dev/null -w "port=%{http_code}\n" http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local
echo "=== 3. webhook 触发拉活 ==="
curl -s -o /dev/null -w "hook=%{http_code}\n" -X POST http://127.0.0.1:9111/hook \
  -H "Content-Type: application/json" -H "Authorization: Bearer cc-remote-selftest" \
  -d '{"session_key":"qqbot:2EB2DD390753D07C3AD3B16BA2667BDF","prompt":"wake-for-diag"}'
sleep 8
echo "=== 4. 拉活后进程 ==="
docker top cc-remote -o pid,etime,cmd 2>/dev/null | grep -a opencode | grep -av grep | head -1
echo "=== 5. 日志最近错误 ==="
docker logs cc-remote --since 3m 2>&1 | grep -a -i -e error -e fail -e acp -e spawn | tail -8
