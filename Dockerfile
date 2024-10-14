FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive

ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV http_proxy=$HTTP_PROXY
ENV https_proxy=$HTTPS_PROXY

RUN echo 'Acquire::http::Proxy "$http_proxy";' >> /etc/apt/apt.conf.d/proxy.conf \
    && echo 'Acquire::https::Proxy "$https_proxy";' >> /etc/apt/apt.conf.d/proxy.conf

RUN sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list && \
    apt-get update && apt-get upgrade -y && apt-get install -y \
    apt-transport-https ca-certificates curl gnupg lsb-release sudo wget

RUN apt-get install -y \
    adb bc bear bison build-essential bzip2 ccache cmake curl device-tree-compiler exfat-fuse \
    fastboot flex fuse g++ g++-aarch64-linux-gnu gcc gcc-aarch64-linux-gnu gdb-multiarch git htop \
    iproute2 libbz2-dev libclang-cpp-dev libelf-dev libncurses-dev libreadline-dev libsqlite3-dev \
    libssl-dev libyaml-cpp-dev locales lsof make net-tools openjdk-11-jdk openssh-server plantuml \
    psmisc python3 qemu-kvm qemu-system qemu-utils rsync scons strace sysstat tar tzdata u-boot-tools \
    unzip vim wget xz-utils zip zlib1g-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

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
RUN if [ "$WITH_GCC" = "true" ]; then /usr/local/bin/pre_configured_scripts/install_gcc.sh; fi
RUN if [ "$WITH_LLVM" = "true" ]; then /usr/local/bin/pre_configured_scripts/install_llvm.sh; fi
RUN if [ "$DISABLE_SNAP" = "true" ]; then /usr/local/bin/pre_configured_scripts/disable_snap.sh; fi
RUN if [ "$WITH_RUST" = "true" ]; then /usr/local/bin/pre_configured_scripts/install_rust.sh; fi
RUN if [ "$WITH_GO" = "true" ]; then /usr/local/bin/pre_configured_scripts/install_go.sh; fi
RUN if [ "$WITH_ZSH" = "true" ]; then /usr/local/bin/pre_configured_scripts/install_zsh.sh; fi
RUN if [ "$CONFIG_GITHUB" = "true" ]; then /usr/local/bin/pre_configured_scripts/configure_github.sh $GH_TOKEN; fi
RUN if [ "$WITH_ASTRONVIM" = "true" ]; then /usr/local/bin/pre_configured_scripts/install_astronvim.sh; fi
RUN if [ "$WITH_VSCODE" = "true" ]; then /usr/local/bin/pre_configured_scripts/install_vsc_ser.sh $CODE_COMMITID; fi

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
