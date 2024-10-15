#!/bin/bash

# 使用环境变量中的代理配置
echo "Attempting to download and install Rust..."
curl https://sh.rustup.rs -sSf | bash -s -- -y
# 配置环境
source $HOME/.cargo/env

# 将Rust环境变量添加到zsh配置
grep -qxF 'source "$HOME/.cargo/env"' ~/.zshrc || echo 'source "$HOME/.cargo/env"' >> ~/.zshrc

# 加载新的zsh配置
source ~/.zshrc