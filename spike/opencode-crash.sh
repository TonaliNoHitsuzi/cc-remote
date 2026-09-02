#!/bin/bash
echo "=== 备份 db ==="
docker exec cc-remote sh -c 'cp /root/.local/share/opencode/opencode.db /root/.local/share/opencode/opencode.db.bak-$(date +%s) 2>&1; ls -la /root/.local/share/opencode/*.db* | head'
echo "=== 容器内手动跑 opencode acp（前台，看 stderr） ==="
docker exec cc-remote sh -c 'cd /home/zzy/AgentRoot/cc-remote && OPENCODE_CONFIG=/app/qq-opencode.json OPENCODE_SERVER_PASSWORD=cc-remote-2026-local timeout 12 /usr/local/bin/opencode acp --port 14098 --hostname 0.0.0.0 2>&1 < /dev/null | head -12'
echo "=== 退出码说明（124=timeout=活着；其他=崩） ==="
