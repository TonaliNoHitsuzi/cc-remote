#!/bin/bash
# cc-remote 收尾清理：归档测试脚本 / 删运行态与凭证 / 删调研副本 / 删 Temp 克隆
set -e
ROOT=~/AgentRoot/cc-remote
ARC=$ROOT/spike/tests-archive
mkdir -p "$ARC"

# 1) 测试/候选脚本 → 归档（保留复用价值；构建/运维助手留根）
for f in acp-client.mjs attach-sim.sh bisect.sh e2e.sh filetest.sh hook.sh hook-trigger.sh \
         host-wake-test.sh inbound.sh m4.sh m4b.sh patch6-selftest.sh patch6-selftest2.sh \
         patch6-selftest3.sh patch6-selftest4.sh patch6-test.mjs patch7-verify.sh probe.sh \
         revert-selftest.sh revert-local-test.sh revert-final-test.sh stoptrace.sh \
         test-opencode.json; do
  if [ -f "$ROOT/spike/$f" ]; then mv "$ROOT/spike/$f" "$ARC/"; fi
done
echo "archived test scripts: $(ls "$ARC" | wc -l)"

# 2) 删运行态 / 凭证 / 日志（库中已有 example，真实凭证在 docker/.env 保留）
rm -f "$ROOT/spike/config.toml" "$ROOT/spike/.config.toml.lock" "$ROOT/spike/acp-trace.log"
rm -rf "$ROOT/spike/data" "$ROOT/spike/work"

# 3) 删调研副本（原件 E:\网络调研 保留）
rm -rf "$ROOT/docs/research"

# 4) 删 Temp 克隆
rm -rf /mnt/c/Users/Zzy/AppData/Local/Temp/opencode/opencode-src \
       /mnt/c/Users/Zzy/AppData/Local/Temp/opencode/cc-connect \
       /mnt/c/Users/Zzy/AppData/Local/Temp/opencode/cc-connect-pr \
       /mnt/c/Users/Zzy/AppData/Local/Temp/opencode/cc-connect-src \
       /mnt/c/Users/Zzy/AppData/Local/Temp/opencode/im-hub-src

echo "=== 清理后 spike/ ==="
ls "$ROOT/spike/"
echo "=== git 状态（预期：docs/research 删除 + tests-archive 新增） ==="
cd "$ROOT" && git status --short | head
