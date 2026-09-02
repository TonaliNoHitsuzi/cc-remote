#!/bin/bash
# revert 物理自测（本地独立 acp，配置文件指定端口 15000 绕 CLI bug）
cd ~/AgentRoot/cc-remote/spike
export HOME=/tmp/oc-test-home XDG_DATA_HOME=/tmp/oc-test-data XDG_CONFIG_HOME=/tmp/oc-test-config
mkdir -p $HOME $XDG_DATA_HOME $XDG_CONFIG_HOME
B=http://127.0.0.1:15000

rm -f /tmp/rv-fifo; mkfifo /tmp/rv-fifo
nohup env OPENCODE_CONFIG=/home/zzy/AgentRoot/cc-remote/spike/test-opencode.json ./bin/opencode acp < /tmp/rv-fifo > /tmp/rv-acp.log 2>&1 &
ACP=$!
exec 3>/tmp/rv-fifo   # 持有写端，stdin 永不 EOF
for i in $(seq 1 20); do
  code=$(curl -s -o /dev/null -w '%{http_code}' $B/doc 2>/dev/null)
  if [ "$code" = "200" ] || [ "$code" = "404" ]; then break; fi
  sleep 1
done
echo "server($code) after ${i}s"
if [ "$code" != "200" ]; then echo FAIL-START; tail -5 /tmp/rv-acp.log; kill $ACP; exit 1; fi

echo "=== 1. 建 session ==="
SID=$(curl -s -X POST $B/session -H 'Content-Type: application/json' -d '{"directory":"/home/zzy/AgentRoot/cc-remote/spike/work"}' | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
echo "session: $SID"

echo "=== 2. 发两条带暗号的消息 ==="
curl -s -X POST $B/session/$SID/message -H 'Content-Type: application/json' -d '{"parts":[{"type":"text","text":"你好，记住暗号是 pineapple 123"}]}' -o /dev/null -w "msg1: %{http_code}\n"
curl -s -X POST $B/session/$SID/message -H 'Content-Type: application/json' -d '{"parts":[{"type":"text","text":"第二句：天空是蓝色的"}]}' -o /dev/null -w "msg2: %{http_code}\n"

echo "=== 3. revert 前验证：问暗号（应知道） ==="
ANS1=$(curl -s -X POST $B/session/$SID/prompt -H 'Content-Type: application/json' -d '{"parts":[{"type":"text","text":"我之前告诉你的暗号是什么？只回暗号"}]}' | python3 -c "
import json,sys
txt=''
try:
  d=json.load(sys.stdin)
  def walk(o):
    global txt
    if isinstance(o,dict):
      if o.get('type')=='text' and isinstance(o.get('text'),str) and len(o['text'])>2: txt+=o['text']
      for v in o.values(): walk(v)
    elif isinstance(o,list):
      for v in o: walk(v)
  walk(d)
except: pass
print(txt[:120])
")
echo "revert前回答: $ANS1"

echo "=== 4. revert 到首条 ==="
FIRST=$(curl -s $B/session/$SID/message | python3 -c "import json,sys; d=json.load(sys.stdin); msgs=d if isinstance(d,list) else d.get('messages',[]); print(msgs[0]['info']['id'] if msgs else '')")
echo "first msg: $FIRST"
curl -s -X POST $B/session/$SID/revert -H 'Content-Type: application/json' -d "{\"messageID\":\"$FIRST\"}" | head -c 200; echo

echo "=== 5. revert 后验证：再问暗号（应不知道） ==="
ANS2=$(curl -s -X POST $B/session/$SID/prompt -H 'Content-Type: application/json' -d '{"parts":[{"type":"text","text":"我之前告诉你的暗号是什么？只回暗号，没有就说不知道"}]}' | python3 -c "
import json,sys
txt=''
try:
  d=json.load(sys.stdin)
  def walk(o):
    global txt
    if isinstance(o,dict):
      if o.get('type')=='text' and isinstance(o.get('text'),str) and len(o['text'])>2: txt+=o['text']
      for v in o.values(): walk(v)
    elif isinstance(o,list):
      for v in o: walk(v)
  walk(d)
except: pass
print(txt[:120])
")
echo "revert后回答: $ANS2"

echo "=== 结论 ==="
echo "session id 未变: $SID"
case "$ANS2" in
  *pineapple*) echo "FAIL: revert 后模型仍记得暗号";;
  *) echo "PASS: revert 物理挤出了上文（prompt 层）";;
esac
kill $ACP 2>/dev/null
echo done
