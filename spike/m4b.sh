#!/bin/bash
# 查 slash 命令与打断的处理痕迹
S=~/AgentRoot/cc-remote/spike
{
  echo "=== builtin/slash 命令 ==="
  grep -a -e "builtin" -e "Builtin" -e "slash" -e "Slash" "$S/serve.log" | tail -10
  echo "=== /stop 与打断 ==="
  grep -a -e "stop" -e "abort" -e "teardown" -e "interrupt" "$S/serve.log" | grep -a -v -e "agent_thought" -e "tool_call" | tail -12
  echo "=== 全部 user 消息 ==="
  grep -a "message received" "$S/serve.log" | grep -a -o "len=[0-9]*" | tr "\n" " "
  echo ""
} > /mnt/c/Users/Zzy/AppData/Local/Temp/opencode/m4b.txt 2>&1
