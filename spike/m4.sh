#!/bin/bash
# M4 命令系统测试核账
S=~/AgentRoot/cc-remote/spike
{
  echo "=== slash 命令处理 ==="
  grep -a -e "cmd" -e "command" -e "/new" -e "/stop" -e "/list" -e "/compress" "$S/serve.log" | grep -a -v "agent_thought" | tail -15
  echo "=== 会话生命周期 ==="
  grep -a -e "session spawned" -e "session released" -e "reset" -e "stop" "$S/serve.log" | grep -a -v "agent_thought" | tail -10
  echo "=== 账本 ==="
  grep -a -c "qqbot: sending" "$S/serve.log"
} > /mnt/c/Users/Zzy/AppData/Local/Temp/opencode/m4-check.txt 2>&1
