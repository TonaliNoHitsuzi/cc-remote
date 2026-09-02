#!/bin/bash
# revert API 自测：对容器 14096 真进程验证 GET messages + POST revert + 会话状态
AUTH="opencode:cc-remote-2026-local"
B="http://127.0.0.1:14096"

code=$(curl -s -o /dev/null -w '%{http_code}' -u $AUTH $B/doc)
echo "server: $code"
[ "$code" = "200" ] || exit 1

echo "=== sessions ==="
curl -s -u $AUTH $B/session | python3 -c "import json,sys; d=json.load(sys.stdin); [print(s['id'], s.get('revert') is not None and 'REVERTED' or 'active', s.get('time',{}).get('created','')[:19]) for s in d] if isinstance(d,list) else print(d)" 2>/dev/null | head -8
SID=$(curl -s -u $AUTH $B/session | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0]['id'] if d else '')" 2>/dev/null)
echo "target session: $SID"
[ -n "$SID" ] || exit 1

echo "=== messages（前3条） ==="
curl -s -u $AUTH "$B/session/$SID/message" | python3 -c "
import json,sys
d=json.load(sys.stdin)
msgs = d if isinstance(d,list) else d.get('messages',[])
print('total:', len(msgs))
for m in msgs[:3]: print(m['info']['id'], m['info']['role'], (m['parts'][0].get('text','') if m.get('parts') else '')[:40])
" 2>/dev/null

FIRST=$(curl -s -u $AUTH "$B/session/$SID/message" | python3 -c "import json,sys; d=json.load(sys.stdin); msgs=d if isinstance(d,list) else d.get('messages',[]); print(msgs[0]['info']['id'] if msgs else '')" 2>/dev/null)
echo "first message: $FIRST"
[ -n "$FIRST" ] || exit 1

echo "=== POST revert（回到首条） ==="
curl -s -u $AUTH -X POST "$B/session/$SID/revert" -H 'Content-Type: application/json' -d "{\"messageID\":\"$FIRST\"}" | head -c 260
echo
echo "=== 会话状态（应带 revert 标记） ==="
curl -s -u $AUTH "$B/session/$SID" | python3 -c "import json,sys; d=json.load(sys.stdin); print('revert:', json.dumps(d.get('revert'))[:200])" 2>/dev/null
echo "revert-selftest done"
