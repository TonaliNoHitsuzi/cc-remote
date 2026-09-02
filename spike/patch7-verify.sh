#!/bin/bash
# 补丁⑦验证：hook 拉活 -> /new -> 期望日志 "reset via revert" + session id 保持
wsl() { /mnt/c/Windows/System32/wsl.exe -d Ubuntu-24.04 -e bash -c "$1"; }
SK="qqbot:2EB2DD390753D07C3AD3B16BA2667BDF"
hook() {
  docker exec cc-remote curl -s -X POST http://127.0.0.1:9111/hook \
    -H "Content-Type: application/json" -H "Authorization: Bearer cc-remote-selftest" \
    -d "{\"session_key\":\"$SK\",\"prompt\":\"$1\"}" -o /dev/null
}

echo "=== 拉活进程 ==="
hook "hi"
sleep 22
docker top cc-remote -o pid,cmd | grep -a opencode | grep -av grep | head -1
SID_BEFORE=$(curl -s -u opencode:cc-remote-2026-local http://127.0.0.1:14096/session | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0]['id'] if d else '')")
echo "session before: $SID_BEFORE"

echo "=== 触发 /new（走 send 管道？不行——/new 是命令。用 hook prompt 发 /new？hook 是 prompt 不是命令解析。改用直接调 engine？")
echo "方案：hook 无法发命令。换：确认 revert 函数先手动 REST 验证（容器内）——cmdNew 的触发只能 QQ 或带命令的入口。"
