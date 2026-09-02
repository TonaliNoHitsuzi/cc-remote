#!/bin/bash
# 通过 /hook 拉活 agent 进程（完全自主测试通道）
docker exec cc-remote curl -s -X POST http://127.0.0.1:9111/hook \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer cc-remote-selftest" \
  -d '{"session_key":"qqbot:2EB2DD390753D07C3AD3B16BA2667BDF","prompt":"自测消息：请只回复 ok"}'
echo
sleep 20
docker top cc-remote -o pid,cmd | grep -a opencode | grep -av grep
docker logs cc-remote --since 1m 2>&1 | grep -a -e "turn complete" -e "hook" | tail -3
