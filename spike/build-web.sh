#!/bin/bash
# 全量构建 cc-connect（含 web 前端）：node 构建 web/dist → golang embed 编译
set -e
SRC=/home/zzy/AgentRoot/cc-remote/spike/src/cc-connect
docker run --rm \
  -v "$SRC/web":/web -v /home/zzy/pnpm-store:/pnpm-store -e PNPM_HOME=/pnpm-store \
  -w /web node:20 bash -lc 'corepack enable && pnpm install --frozen-lockfile 2>/dev/null || pnpm install; pnpm build && ls -la dist | head -3'
docker run --rm \
  -v "$SRC":/src -v /home/zzy/gocache:/gocache -v /home/zzy/gomodcache:/gomodcache \
  -e GOCACHE=/gocache -e GOMODCACHE=/gomodcache -e GOPROXY=https://goproxy.cn,direct \
  -w /src golang:1.25 go build -buildvcs=false -trimpath -o /src/cc-connect-web ./cmd/cc-connect
echo "BUILT: $SRC/cc-connect-web"
