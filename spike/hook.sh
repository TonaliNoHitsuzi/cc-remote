#!/bin/bash
# 稳定 hook 触发（脚本文件，避免引号问题）
SK="qqbot:2EB2DD390753D07C3AD3B16BA2667BDF"
BODY=$(python3 -c 'import sys,json; print(json.dumps({"session_key":"'$SK'","prompt":sys.argv[1]}))' "$1")
docker exec cc-remote curl -s -X POST http://127.0.0.1:9111/hook \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer cc-remote-selftest" \
  -d "$BODY"
echo
