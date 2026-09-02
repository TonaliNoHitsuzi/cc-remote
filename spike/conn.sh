#!/bin/bash
# 分层连通性：WSL 内 / 容器 / 宿主
echo "=== WSL-宿主 连容器端口（WSL 视角） ==="
for p in 9111 14096; do
  c=$(curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:$p/ --max-time 3 2>/dev/null)
  echo "WSL->127.0.0.1:$p = [$c]"
done
echo "=== 容器内自听 ==="
docker exec cc-remote sh -c "for p in 9111 14096; do (echo > /dev/tcp/127.0.0.1/\$p) 2>/dev/null && echo \$p open || echo \$p CLOSED; done"
echo "=== 宿主 curl（Windows PowerShell 侧另测） ==="
echo "（下面的在 Windows 侧跑）"
