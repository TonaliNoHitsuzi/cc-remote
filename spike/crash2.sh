#!/bin/bash
echo "=== RestartCount / OOM / Status ==="
docker inspect cc-remote --format 'RC={{.RestartCount}} OOM={{.State.OOMKilled}} Status={{.State.Status}} Started={{.State.StartedAt}}'
echo "=== 末次 30 行日志 ==="
docker logs cc-remote --tail 30 2>&1
echo "=== 60 秒内重启计数（看是否循环） ==="
docker inspect cc-remote --format '{{.RestartCount}}'
