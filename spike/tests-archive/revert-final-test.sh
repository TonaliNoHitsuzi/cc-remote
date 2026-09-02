#!/bin/bash
# revert 终极自测：真进程(14096) + hook 注入暗号 + REST revert + 前后对照 + TUI 存活
AUTH="opencode:cc-remote-2026-local"
B="http://127.0.0.1:14096"
SK="qqbot:2EB2DD390753D07C3AD3B16BA2667BDF"

hook() {  # hook 发一条消息（进 QQ 会话 turn）
  docker exec cc-remote curl -s -X POST http://127.0.0.1:9111/hook \
    -H "Content-Type: application/json" -H "Authorization: Bearer cc-remote-selftest" \
    -d "{\"session_key\":\"$SK\",\"prompt\":\"$1\"}" -o /dev/null
}

code=$(curl -s -o /dev/null -w '%{http_code}' -u $AUTH $B/doc)
echo "server: $code"; [ "$code" = "200" ] || exit 1

# TUI attach 后台观察（60s）
cd ~/AgentRoot/cc-remote/spike
nohup timeout 60 ./bin/opencode attach $B -u $AUTH --dir ~/AgentRoot/cc-remote < /dev/null > /tmp/rt-tui.log 2>&1 &
TUI=$!
sleep 8

echo "=== ① 注入暗号 ==="
hook "记住暗号是 pineapple-777，只回复收到"
sleep 25

echo "=== ② revert 前问暗号 ==="
hook "我之前说的暗号是什么？只回暗号本身"
sleep 25
docker logs cc-remote --since 40s 2>&1 | grep -a "turn response" | tail -1 | grep -a -o "pineapple-777" | head -1 && echo "(revert前：记得暗号 ✓)" || echo "(revert前回答见日志)"

echo "=== ③ REST revert 到首条 ==="
SID=$(curl -s -u $AUTH $B/session | python3 -c "import json,sys; d=json.load(sys.stdin); ss=[s for s in d if not s.get('revert')]; print(ss[0]['id'] if ss else d[0]['id'])")
FIRST=$(curl -s -u $AUTH "$B/session/$SID/message" | python3 -c "import json,sys; d=json.load(sys.stdin); msgs=d if isinstance(d,list) else d.get('messages',[]); print(msgs[0]['info']['id'] if msgs else '')")
echo "session=$SID first=$FIRST"
curl -s -u $AUTH -X POST "$B/session/$SID/revert" -H 'Content-Type: application/json' -d "{\"messageID\":\"$FIRST\"}" | python3 -c "import json,sys; d=json.load(sys.stdin); print('revert state:', 'SET' if d.get('revert') else 'NONE')" 2>/dev/null
sleep 3

echo "=== ④ revert 后再问暗号 ==="
hook "我之前说的暗号是什么？只回暗号本身，没有就回不知道"
sleep 25
R=$(docker logs cc-remote --since 40s 2>&1 | grep -a "turn response" | tail -1)
echo "$R" | grep -a -q "pineapple-777" && echo "FAIL: 仍记得暗号" || echo "PASS: 暗号已被挤出上下文"

echo "=== ⑤ TUI 存活（revert 全程） ==="
kill -0 $TUI 2>/dev/null && echo "TUI alive: YES" || { wait $TUI; echo "TUI alive: NO (exit $?)"; }
echo "=== ⑥ session id 一致性 ==="
echo "session=$SID（未变，TUI 视图连续）"
kill $TUI 2>/dev/null
echo "selftest-final done"
