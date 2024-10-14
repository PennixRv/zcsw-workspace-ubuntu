FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list && \
    apt-get update && apt-get upgrade -y && apt-get install -y \
    apt-transport-https ca-certificates curl gnupg lsb-release sudo wget

# 创建脚本存放目录
RUN mkdir -p /usr/local/bin/pre_configured_scripts

# 复制安装脚本到容器中的指定目录
COPY scripts/ /usr/local/bin/pre_configured_scripts/

# 赋予执行权限
RUN chmod +x /usr/local/bin/pre_configured_scripts/*.sh

# 根据参数条件性执行脚本
ARG WITH_GCC
ARG WITH_LLVM
ARG WITH_RUST
ARG WITH_GO
ARG DISABLE_SNAP

RUN if [ "$WITH_GCC" = "true" ]; then \
        /usr/local/bin/pre_configured_scripts/install_gcc.sh; \
    fi && \
    if [ "$WITH_LLVM" = "true" ]; then \
        /usr/local/bin/pre_configured_scripts/install_llvm.sh; \
    fi && \
    if [ "$DISABLE_SNAP" = "true" ]; then \
        /usr/local/bin/pre_configured_scripts/disable_snap.sh; \
    fi && \
    if [ "$WITH_RUST" = "true" ]; then \
        /usr/local/bin/pre_configured_scripts/install_rust.sh; \
    fi && \
    if [ "$WITH_GO" = "true" ]; then \
        /usr/local/bin/pre_configured_scripts/install_go.sh; \
    fi

# 清理
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
