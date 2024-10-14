#!/bin/bash

# 更新并升级系统包
sudo apt update && sudo apt upgrade -y

# 安装构建工具和依赖
sudo apt install -y build-essential curl

# 下载并安装 Rust 工具链
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# 将 Rust 环境变量加载到当前 shell 环境中
source $HOME/.cargo/env

# 在 .bashrc 中添加 Rust 环境变量（如果还没有）
grep -qxF 'source "$HOME/.cargo/env"' ~/.bashrc || echo 'source "$HOME/.cargo/env"' >> ~/.zshrc

# 重新加载 .bashrc 使设置生效
source ~/.zshrc
