FROM docker.1panel.dev/ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive

ARG PROXY_ENABLED
ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV http_proxy=$HTTP_PROXY
ENV https_proxy=$HTTPS_PROXY

RUN if [ "$PROXY_ENABLED" = "true" ]; then \
        echo "Setting up proxies"; \
        echo "Acquire::http::Proxy \"$HTTP_PROXY\";" > /etc/apt/apt.conf.d/01proxy && \
        echo "Acquire::https::Proxy \"$HTTPS_PROXY\";" >> /etc/apt/apt.conf.d/01proxy; \
        export HTTP_PROXY="$HTTP_PROXY" && \
        export HTTPS_PROXY="$HTTPS_PROXY"; \
    else \
        echo "Proxies not enabled"; \
    fi

RUN if [ "$PROXY_ENABLED" != "true" ]; then \
        cp /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.bak && \
        echo "Types: deb" > /etc/apt/sources.list.d/ubuntu.sources && \
        echo "URIs: http://mirrors.tuna.tsinghua.edu.cn/ubuntu/" >> /etc/apt/sources.list.d/ubuntu.sources && \
        echo "Suites: noble noble-updates noble-security" >> /etc/apt/sources.list.d/ubuntu.sources && \
        echo "Components: main restricted universe multiverse" >> /etc/apt/sources.list.d/ubuntu.sources && \
        echo "Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg" >> /etc/apt/sources.list.d/ubuntu.sources; \
    fi && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release sudo wget

RUN apt-get install -y \
    bear bison bzip2 ccache cmake curl \
    device-tree-compiler flex fuse htop iproute2 \
    libbz2-dev libelf-dev libncurses-dev libreadline-dev \
    libsqlite3-dev libssl-dev libyaml-cpp-dev locales lsof \
    make net-tools openssh-server plantuml psmisc python3 \
    rsync scons strace sysstat tar tzdata u-boot-tools \
    unzip vim wget xz-utils zip zlib1g-dev

RUN mkdir -p /usr/local/bin/pre_configured_scripts
COPY scripts/ /usr/local/bin/pre_configured_scripts/
RUN chmod +x /usr/local/bin/pre_configured_scripts/*.sh

ARG USER_ID
ARG GROUP_ID
ARG USER_NAME
ARG GROUP_NAME
ARG HOME_DIR
RUN groupadd -g $GROUP_ID $GROUP_NAME && \
    useradd -m -u $USER_ID -g $GROUP_ID -s /bin/bash -d $HOME_DIR $USER_NAME && \
    echo "$USER_NAME:$USER_NAME" | chpasswd && \
    echo "$USER_NAME ALL=(ALL:ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/$USER_NAME

ARG MOUNT_PATH
WORKDIR $MOUNT_PATH

USER $USER_ID:$GROUP_ID

ARG WITH_GCC
ARG WITH_LLVM
ARG WITH_RUST
ARG WITH_GO
ARG DISABLE_SNAP
ARG WITH_ZSH
ARG CONFIG_GITHUB
ARG WITH_ASTRONVIM
ARG WITH_VSCODE
ARG GH_TOKEN
ARG CODE_COMMITID
RUN if [ "$DISABLE_SNAP" = "true" ]; then /bin/bash /usr/local/bin/pre_configured_scripts/disable_snap.sh; fi
RUN if [ "$WITH_ZSH" = "true" ]; then /bin/bash /usr/local/bin/pre_configured_scripts/install_zsh.sh; fi
RUN if [ "$WITH_RUST" = "true" ]; then /bin/bash /usr/local/bin/pre_configured_scripts/install_rust.sh; fi
RUN if [ "$WITH_LLVM" = "true" ]; then /bin/bash /usr/local/bin/pre_configured_scripts/install_llvm.sh; fi
RUN if [ "$WITH_GCC" = "true" ]; then /bin/bash /usr/local/bin/pre_configured_scripts/install_gcc.sh; fi
RUN if [ "$WITH_GO" = "true" ]; then /bin/bash /usr/local/bin/pre_configured_scripts/install_go.sh; fi
RUN if [ "$CONFIG_GITHUB" = "true" ]; then /bin/bash /usr/local/bin/pre_configured_scripts/configure_github.sh; fi
RUN if [ "$WITH_ASTRONVIM" = "true" ]; then /bin/bash /usr/local/bin/pre_configured_scripts/install_astronvim.sh; fi
RUN if [ "$WITH_VSCODE" = "true" ]; then /bin/bash /usr/local/bin/pre_configured_scripts/install_vsc_ser.sh; fi

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
