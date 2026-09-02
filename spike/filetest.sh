#!/bin/bash
# v2：等 QQ 消息激活会话后立即下发文件；每10s轮询，最多5分钟
LOG=~/AgentRoot/cc-remote/spike/serve.log
OUT=/tmp/send-out5.txt
for i in $(seq 1 30); do
  sleep 10
  n=$(grep -a -c "message received" "$LOG" 2>/dev/null)
  if [ "${n:-0}" -gt 0 ]; then
    CC_DATA_DIR=/home/zzy/AgentRoot/cc-remote/spike/data \
      ~/AgentRoot/cc-remote/spike/bin/cc-connect-dev send \
      --file /tmp/cc-file-test.txt --message file-route-test > "$OUT" 2>&1
    echo "rc=$?" >> "$OUT"
    cp "$OUT" /mnt/c/Users/Zzy/AppData/Local/Temp/opencode/send-out5.txt 2>/dev/null
    bash ~/AgentRoot/cc-remote/spike/status.sh
    exit 0
  fi
done
echo "TIMEOUT: no message in 300s" > /mnt/c/Users/Zzy/AppData/Local/Temp/opencode/send-out5.txt
