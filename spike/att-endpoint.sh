#!/bin/bash
echo "=== attach 关键端点响应 ==="
for ep in "/doc" "/config/providers" "/session" "/config" ; do
  c=$(curl -s -o /tmp/ep.out -w "%{http_code}" --noproxy "*" --max-time 5 "http://127.0.0.1:14096$ep" -u opencode:cc-remote-2026-local 2>/dev/null)
  echo "$ep -> $c | $(head -c 120 /tmp/ep.out 2>/dev/null | tr -d '\n')"
done
echo "=== 进程真实名 ==="
docker top cc-remote -o pid,cmd 2>/dev/null | tail -5
