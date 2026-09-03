#!/bin/bash
echo "=== RestartCount / 上次退出码 ==="
docker inspect cc-remote --format 'RC={{.RestartCount}} ExitCode={{.State.ExitCode}} Status={{.State.Status}} Started={{.State.StartedAt}} Finished={{.State.FinishedAt}}'
echo "=== 上次容器日志（挂掉前最后 20 行，09:40-09:56） ==="
docker logs cc-remote --since 25m 2>&1 | head -30
echo "=== 系统层：OOM / panic 痕迹 ==="
docker logs cc-remote --since 25m 2>&1 | grep -a -i -e panic -e "fatal" -e oom -e "signal" -e killed | head -5
