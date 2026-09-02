#!/bin/bash
cd ~/AgentRoot/cc-remote/spike
echo "=== 当前代理环境 ==="
env | grep -i -e proxy | head -6
echo "=== attach A: 不 unset（模拟现状，应 Unable） ==="
timeout 10 script -qc "timeout 8 ./bin/opencode attach http://127.0.0.1:14096 -u opencode -p cc-remote-2026-local --dir ~/AgentRoot/cc-remote" /dev/null 2>&1 | grep -a -i -e "unable" -e "error" | head -2
echo "=== attach B: unset 全部代理（应稳定） ==="
timeout 10 script -qc "env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY -u all_proxy -u ALL_PROXY ./bin/opencode attach http://127.0.0.1:14096 -u opencode -p cc-remote-2026-local --dir ~/AgentRoot/cc-remote" /dev/null 2>&1 | grep -a -i -e "unable" -e "error" | head -2
echo "=== B 若无 error = 代理劫持确认 ==="
