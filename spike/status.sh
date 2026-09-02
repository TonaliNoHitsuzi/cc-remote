#!/bin/bash
# spike 状态一键检查：进程/网关/最近发送数/最近turn
S=~/AgentRoot/cc-remote/spike
p=$(ps aux | grep -a "[c]c-connect-dev" | wc -l)
r=$(grep -a -c "platform ready" $S/serve.log 2>/dev/null)
s=$(grep -a -c "qqbot: sending" $S/serve.log 2>/dev/null)
t=$(grep -a -c "turn complete" $S/serve.log 2>/dev/null)
h=$(grep -a "msg-count" $S/serve.log 2>/dev/null | wc -l)
echo "proc=$p ready=$r sends=$s turns=$t"
