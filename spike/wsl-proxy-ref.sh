# WSL 代理环境（undici/bun 兼容：no_proxy 用 CIDR/纯词条，禁用 `*` 通配，确保 localhost 永不走代理）
export http_proxy=http://127.0.0.1:7897
export https_proxy=http://127.0.0.1:7897
export HTTP_PROXY=http://127.0.0.1:7897
export HTTPS_PROXY=http://127.0.0.1:7897
export no_proxy="127.0.0.1,localhost,::1,192.168.0.0/16,172.16.0.0/12,172.31.0.0/16,10.0.0.0/8"
export NO_PROXY="127.0.0.1,localhost,::1,192.168.0.0/16,172.16.0.0/12,172.31.0.0/16,10.0.0.0/8"
