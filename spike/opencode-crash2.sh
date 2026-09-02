#!/bin/bash
echo "=== 容器内跑 opencode acp，stderr 落文件 ==="
docker exec cc-remote sh -c 'cd /home/zzy/AgentRoot/cc-remote && OPENCODE_CONFIG=/app/qq-opencode.json OPENCODE_SERVER_PASSWORD=cc-remote-2026-local timeout 12 /usr/local/bin/opencode acp --port 14098 --hostname 0.0.0.0 > /tmp/oc-crash.log 2>&1 < /dev/null; echo "EXITCODE=$?"'
echo "=== 崩溃日志 ==="
docker exec cc-remote sh -c 'cat /tmp/oc-crash.log 2>/dev/null | head -20'
echo "=== (无内容=可能活着被timeout杀 124) ==="
