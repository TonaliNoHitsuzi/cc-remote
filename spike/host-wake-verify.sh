#!/bin/bash
# 宿主唤醒验证：webhook 发消息 -> turn -> 进程 + 回复
RESP=$(curl -s -X POST http://127.0.0.1:9111/hook \
  -H "Content-Type: application/json" -H "Authorization: Bearer cc-remote-selftest" \
  -d '{"session_key":"qqbot:2EB2DD390753D07C3AD3B16BA2667BDF","prompt":"唤醒测试，只回ok"}')
echo "hook resp: $RESP"
sleep 8
echo "=== 进程 ==="
docker top cc-remote -o pid,etime,cmd 2>/dev/null | grep -a opencode | grep -av grep | head -1
echo "(空=未拉活)"
echo "=== 14096 端口 ==="
curl -s -o /dev/null -w "port=%{http_code}\n" http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local
echo "=== turn 日志 ==="
docker logs cc-remote --since 1m 2>&1 | grep -a -e "turn complete" -e "session spawned" -e "acp" -e ERROR | tail -5
