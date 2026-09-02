#!/bin/bash
cd ~/AgentRoot/cc-remote/spike
# 模拟：代理软件没开（7897 无服务），但环境变量在（wsl 会话常态）
echo "=== 7897 是否在听（代理软件状态） ==="
(echo > /dev/tcp/127.0.0.1/7897) 2>/dev/null && echo "proxy UP" || echo "proxy DOWN (代理软件未开)"
echo "=== 当前 no_proxy ==="
echo "$no_proxy"
echo "=== attach（带代理环境变量 + clean no_proxy）==="
timeout 10 script -qc "timeout 8 ./bin/opencode attach http://127.0.0.1:14096 -u opencode -p cc-remote-2026-local --dir ~/AgentRoot/cc-remote" /dev/null 2>&1 | grep -a -i -e "unable" -e "error" | head -2
echo "=== (清空输出=clean no_proxy 生效，localhost 绕过代理，稳定) ==="
echo "=== 对照组：老的 * 通配 no_proxy（应 Unable） ==="
timeout 10 script -qc "env no_proxy='192.168.*,10.*,127.*,localhost' ./bin/opencode attach http://127.0.0.1:14096 -u opencode -p cc-remote-2026-local --dir ~/AgentRoot/cc-remote" /dev/null 2>&1 | grep -a -i -e "unable" | head -1
