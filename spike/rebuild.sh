#!/bin/bash
# 重编译打补丁的 cc-connect 并以 zzy 重启 spike serve
set -e
docker run --rm \
  -v /home/zzy/AgentRoot/cc-remote/spike/src/cc-connect:/src \
  -v /home/zzy/gocache:/gocache -v /home/zzy/gomodcache:/gomodcache \
  -e GOCACHE=/gocache -e GOMODCACHE=/gomodcache -e GOPROXY=https://goproxy.cn,direct \
  -w /src golang:1.25 go build -tags no_web -buildvcs=false -trimpath -o /src/cc-connect-dev ./cmd/cc-connect
chown zzy:zzy /home/zzy/AgentRoot/cc-remote/spike/src/cc-connect/cc-connect-dev
mv /home/zzy/AgentRoot/cc-remote/spike/src/cc-connect/cc-connect-dev /home/zzy/AgentRoot/cc-remote/spike/bin/cc-connect-dev
pkill -x cc-connect-dev || true
sleep 2
cd /home/zzy/AgentRoot/cc-remote/spike
rm -f serve.log
nohup ./bin/cc-connect-dev --config /home/zzy/AgentRoot/cc-remote/spike/config.toml > serve.log 2>&1 &
sleep 10
bash /home/zzy/AgentRoot/cc-remote/spike/status.sh
