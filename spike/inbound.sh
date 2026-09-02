#!/bin/bash
# 入站附件日志检查
L=~/AgentRoot/cc-remote/spike/serve.log
{
  grep -a -e "c2c message received" -e "download" -e "turn complete" -e "session spawned" -e "prompt" "$L" | tail -12
  echo "=== send summary ==="
  grep -a -c "qqbot: sending" "$L"
} > /mnt/c/Users/Zzy/AppData/Local/Temp/opencode/inbound-log.txt 2>&1
