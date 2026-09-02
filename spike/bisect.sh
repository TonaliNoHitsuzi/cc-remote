#!/bin/bash
# 二分：config 影响 & server 端口
cd ~/AgentRoot/cc-remote/spike
echo "--- A: test config (server.port=15000)"
timeout 8 env OPENCODE_CONFIG=/home/zzy/AgentRoot/cc-remote/spike/test-opencode.json ./bin/opencode acp < <(sleep 9) > /tmp/ta.log 2>&1
echo "A rc=$?"; head -3 /tmp/ta.log
ss -tln | grep 15000 && echo "A: port 15000 was listening"
echo "--- B: no config"
timeout 8 ./bin/opencode acp < <(sleep 9) > /tmp/tb.log 2>&1
echo "B rc=$?"; head -3 /tmp/tb.log
