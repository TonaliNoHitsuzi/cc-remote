# cc-remote 生产镜像
# 二进制来源（spike 实测验证，勿轻换）：
#   - cc-connect-dev：main@b39c11f 源码编译（-tags no_web），含 4 个本地补丁：
#     1. agent/acp/mapping.go: agent_thought_chunk → EventThinking（思维链过滤）
#     2. core/engine.go: 按钮平台跳过"已允许"确认
#     3. core/engine.go: turnCancelled 标志 + 打断空响应静默（NO_REPLY）
#     （补丁复现见 spike/优化-结论.md）
#   - opencode：v1.18.26 官方 linux-x64 二进制
FROM debian:bookworm-slim

# 国内镜像源（官方源国内极慢）
RUN sed -i 's|deb.debian.org|mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list.d/debian.sources

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates bash curl git tzdata procps \
    && rm -rf /var/lib/apt/lists/* \
    && ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

COPY spike/bin/cc-connect-dev /usr/local/bin/cc-connect
COPY spike/bin/opencode /usr/local/bin/opencode
RUN chmod +x /usr/local/bin/cc-connect /usr/local/bin/opencode \
    && mkdir -p /data /share /skills

# 生产配置与提示词（挂载覆盖，见 compose volumes）
COPY docker/config.toml /app/config.toml
COPY docker/qq-style.md /app/qq-style.md
COPY docker/qq-opencode.json /app/qq-opencode.json

WORKDIR /app
ENTRYPOINT ["cc-connect", "--config", "/app/config.toml"]
