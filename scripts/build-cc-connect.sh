#!/bin/bash
# 构建 cc-connect 补丁版二进制（开源复现路径）
# 用法：bash scripts/build-cc-connect.sh [输出目录，默认 spike/bin]
set -e
OUT="${1:-spike/bin}"
WORK=$(mktemp -d)
echo "[1/4] clone upstream main"
git clone --depth 50 https://github.com/chenhg5/cc-connect "$WORK/cc-connect"
cd "$WORK/cc-connect"
git checkout b39c11f 2>/dev/null || echo "(commit b39c11f not reachable, using HEAD)"

echo "[2/4] apply patches"
for p in "$(dirname "$0")"/../patches/*.patch; do
  echo "  applying $(basename "$p")"
  git apply --check "$p" && git apply "$p" || echo "  WARN: $p failed to apply (可能已合并上游，跳过)"
done

echo "[3/4] docker build (golang:1.25)"
docker run --rm -v "$PWD":/src -v "${HOME}/gocache":/gocache -v "${HOME}/gomodcache":/gomodcache \
  -e GOCACHE=/gocache -e GOMODCACHE=/gomodcache -e GOPROXY=https://goproxy.cn,direct \
  -w /src golang:1.25 go build -tags no_web -buildvcs=false -trimpath -o /src/cc-connect-dev ./cmd/cc-connect

echo "[4/4] install -> $OUT"
mkdir -p "$OUT"
mv cc-connect-dev "$OUT/cc-connect-dev"
echo "done: $OUT/cc-connect-dev"
