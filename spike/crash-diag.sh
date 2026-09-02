#!/bin/bash
echo "=== RestartCount / status ==="
docker inspect cc-remote --format 'RestartCount={{.RestartCount}} Status={{.State.Status}} OOM={{.State.OOMKilled}}'
echo "=== 末次启动日志（崩溃前） ==="
docker logs cc-remote --tail 25 2>&1
echo "=== uptime ==="
docker inspect cc-remote --format '{{.State.StartedAt}}'
