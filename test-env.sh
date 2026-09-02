#!/bin/bash
set -euo pipefail

pass=0
fail=0

ok()   { echo "  ✓ $1"; pass=$((pass+1)); }
fail() { echo "  ✗ $1"; fail=$((fail+1)); }

echo "=== cc-remote 环境检查 ==="

echo "[1] OS"
if grep -qi "ubuntu" /etc/os-release 2>/dev/null; then ok "Ubuntu detected"; else fail "not Ubuntu"; fi

echo "[2] Docker"
if command -v docker &>/dev/null; then ok "docker $(docker --version | awk '{print $3}' | tr -d ',')"; else fail "docker not found"; fi

echo "[3] Docker daemon"
if docker info &>/dev/null; then ok "daemon running"; else fail "daemon not running or no permission"; fi

echo "[4] opencode"
if command -v opencode &>/dev/null; then ok "opencode found"; else fail "opencode not found"; fi

echo "[5] Config dirs"
for d in ~/.config/opencode ~/.local/share/opencode; do
  if [ -d "$d" ]; then ok "$d exists"; else fail "$d missing"; fi
done

echo ""
echo "=== 结果: ${pass} passed, ${fail} failed ==="
[ "$fail" -eq 0 ] && echo "All good." || echo "Check failed items above."
