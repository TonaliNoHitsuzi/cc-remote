#!/bin/bash
# 从 CRLF 污染的 src 仓库洗出纯净补丁
set -e
SRC=~/AgentRoot/cc-remote/spike/src/cc-connect
OUT=~/AgentRoot/cc-remote/patches/cc-remote-local.patch
cd "$SRC"
FILES="agent/acp/mapping.go agent/acp/session.go core/engine.go"
# 备份我们的版本 → 恢复 HEAD（LF）→ 归一化回写 → diff
for f in $FILES; do
  cp "$f" "/tmp/ours-$(basename $f)"
  git checkout -- "$f"
  tr -d '\r' < "/tmp/ours-$(basename $f)" > "$f"
done
git diff -- $FILES > "$OUT"
wc -l "$OUT"
rm -f /tmp/ours-*.go
