#!/bin/bash
# 长程任务核对：消息账本 + notes.md 内容
S=~/AgentRoot/cc-remote/spike
{
  echo "=== 消息发送账本 ==="
  grep -a -c "qqbot: sending" $S/serve.log
  grep -a -c "permission request" $S/serve.log
  grep -a -c "turn complete" $S/serve.log
  echo "=== notes.md ==="
  cat $S/work/progress/notes.md 2>&1
} > /mnt/c/Users/Zzy/AppData/Local/Temp/opencode/e2e-check.txt 2>&1
