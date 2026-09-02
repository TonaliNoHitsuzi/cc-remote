#!/bin/bash
echo "=== 唤醒后进程持续存活（每3s ×6） ==="
curl -s -o /dev/null -w "wake=%{http_code}\n" --noproxy '*' --max-time 5 -X POST http://127.0.0.1:9111/hook \
  -H "Content-Type: application/json" -H "Authorization: Bearer cc-remote-selftest" \
  -d '{"session_key":"qqbot:2EB2DD390753D07C3AD3B16BA2667BDF","prompt":"wake"}'
for i in $(seq 1 6); do
  p=$(docker top cc-remote -o cmd 2>/dev/null | grep -a opencode | grep -av grep | head -1)
  echo "t${i}: proc=[$p]"
  sleep 3
done
echo "=== config 里 agent_session_idle 实际值 ==="
docker exec cc-remote sh -c 'grep -c agent_session_idle /app/config.toml; grep agent_session_idle /app/config.toml'
echo "=== cc-connect 启动日志 idle 相关 ==="
docker logs cc-remote 2>&1 | grep -a -i -e idle -e "agent_session" | head -5
