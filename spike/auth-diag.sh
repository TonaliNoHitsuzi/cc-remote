#!/bin/bash
echo "=== auth.json 位置与内容(容器内) ==="
docker exec cc-remote sh -c 'ls -la /root/.local/share/opencode/ 2>&1'
echo "=== auth.json 是否含 deepseek ==="
docker exec cc-remote sh -c 'grep -o -i deepseek /root/.local/share/opencode/auth.json 2>/dev/null | head -1; echo "auth-provider-hits=$(grep -c -i -E "deepseek|zhipu|kimi" /root/.local/share/opencode/auth.json 2>/dev/null)"'
echo "=== auth 文件实际内容键 ==="
docker exec cc-remote sh -c 'cat /root/.local/share/opencode/auth.json 2>/dev/null | head -c 400'
echo ""
echo "=== opencode.log 尾部 ==="
docker exec cc-remote sh -c 'tail -15 /root/.local/share/opencode/log/opencode.log 2>/dev/null'
echo "=== 挂载验证：宿主侧 ~/.local/share/opencode ==="
ls -la /home/zzy/.local/share/opencode/ 2>&1 | head
grep -o -i -E 'deepseek|zhipu' /home/zzy/.local/share/opencode/auth.json 2>/dev/null | sort -u | head
