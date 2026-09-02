#!/bin/bash
# 端口链路探测：容器内 / WSL 宿主 两层
URL_AUTH="http://127.0.0.1:14096/doc"
echo "== in-container =="
docker exec cc-remote curl -s -u opencode:cc-remote-2026-local -o /dev/null -w '%{http_code}\n' "$URL_AUTH" || echo "in-container FAILED"
echo "== wsl-host =="
curl -s -u opencode:cc-remote-2026-local -o /dev/null -w '%{http_code}\n' "$URL_AUTH" || echo "wsl-host FAILED"
echo "== no-auth (expect 401) =="
curl -s -o /dev/null -w '%{http_code}\n' "$URL_AUTH" || true
