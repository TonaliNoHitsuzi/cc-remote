#!/bin/bash
# 定位空响应消息的发送路径
S=~/AgentRoot/cc-remote/spike
{
  grep -a -n -e "stop" -e "empty" -e "NO_REPLY" -e "silent" -e "sending" "$S/serve.log" | grep -a -v -e "agent_thought" -e "thought_chunk" | tail -25
} > /mnt/c/Users/Zzy/AppData/Local/Temp/opencode/stop-trace.txt 2>&1
