#!/bin/bash
echo "=== 纯 NO_PROXY 直连 9111 ==="
curl -s -o /dev/null -w "9111=%{http_code}\n" --noproxy "*" --max-time 3 http://127.0.0.1:9111/hook
echo "=== 纯 NO_PROXY 直连 14096 ==="
curl -s -o /dev/null -w "14096=%{http_code}\n" --noproxy "*" --max-time 3 http://127.0.0.1:14096/doc -u opencode:cc-remote-2026-local
echo "=== attach 前先验证（TUI 闪退是否代理劫持） ==="
echo "opencode attach 读 http_proxy 环境变量，需 NO_PROXY=127.* 或 unset proxy。当前NO_PROXY=$NO_PROXY"
