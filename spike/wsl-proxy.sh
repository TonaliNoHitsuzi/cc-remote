#!/bin/bash
echo "=== WSL 当前 proxy 环境 ==="
env | grep -i -e proxy
echo "=== no_proxy 内容（看 127/localhost 覆盖） ==="
echo "no_proxy=$no_proxy"
echo "NO_PROXY=$NO_PROXY"
echo "=== WSL 继承来源（WSLENV） ==="
echo "WSLENV=$WSLENV"
echo "=== ~/.bashrc / ~/.profile / /etc/wsl.conf 里的 proxy ==="
grep -rn -i -e proxy -e export /home/zzy/.bashrc /home/zzy/.profile /home/zzy/.bash_profile 2>/dev/null | grep -i -e proxy | head -10
echo "=== etc profile ==="
grep -rn -i proxy /etc/profile /etc/profile.d/*.sh /etc/environment 2>/dev/null | head -10
