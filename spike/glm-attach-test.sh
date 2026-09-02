#!/bin/bash
echo "=== 唤醒 ==="
curl -s -o /dev/null -w "wake=%{http_code}\n" --noproxy "*" --max-time 5 -X POST http://127.0.0.1:9111/hook \
  -H "Content-Type: application/json" -H "Authorization: Bearer cc-remote-selftest" \
  -d '{"session_key":"qqbot:2EB2DD390753D07C3AD3B16BA2667BDF","prompt":"wake-glm-test"}'
sleep 10
echo "=== 进程 ==="
docker top cc-remote -o pid,cmd 2>/dev/null | grep -a opencode | grep -av grep | head -1
echo "=== 宿主 14096 ==="
curl -s -o /dev/null -w "14096=%{http_code}\n" --noproxy "*" --max-time 4 http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local
echo "=== 容器内 14096 监听(tcp/tcp6) ==="
docker exec cc-remote sh -c 'cat /proc/net/tcp6 /proc/net/tcp 2>/dev/null | awk "NR>1 {print \$2}" | grep -i 3700 | head -2'
echo "(空=tcp/tcp6 无14096)"
echo "=== attach 闪退测试（noproxy + 进程活着） ==="
cd ~/AgentRoot/cc-remote/spike
timeout 12 env NO_PROXY=127.0.0.1,localhost no_proxy=127.0.0.1,localhost ./bin/opencode attach http://127.0.0.1:14096 -u opencode -p cc-remote-2026-local --dir ~/AgentRoot/cc-remote < /dev/null 2>&1 | grep -a -i -e error -e unable -e attach | head -3
echo "(无 error 输出=稳定)"
