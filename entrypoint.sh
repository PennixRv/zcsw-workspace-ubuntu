#!/bin/bash

# 运行时配置
source $HOME/.bashrc

if [ "$WITH_ZSH" = "true" ]; then
    /usr/local/bin/pre_configured_scripts/install_zsh.sh
fi

if [ "$CONFIG_GITHUB" = "true" ]; then
    /usr/local/bin/pre_configured_scripts/configure_github.sh
fi

if [ "$WITH_ASTRONVIM" = "true" ]; then
    /usr/local/bin/pre_configured_scripts/install_astronvim.sh
fi

if [ "$WITH_VSCODE" = "true" ]; then
    /usr/local/bin/pre_configured_scripts/install_vsc_ser.sh
fi

if [ ! -d "$MOUNT_PATH" ]; then
    mkdir -p $MOUNT_PATH
fi
chown $USER_NAME:$GROUP_NAME $MOUNT_PATH

exec "$@"
