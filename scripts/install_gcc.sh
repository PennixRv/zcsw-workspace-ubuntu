#!/bin/bash

# 更新系统并安装基础依赖
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

# 添加 Ubuntu 工具链 PPA (包含最新的 GCC 版本)
sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
sudo apt update

# 安装最新的 GCC、G++ 和构建工具
sudo apt install -y gcc-14 g++-14 make build-essential libgcc-14-dev

# 设置默认 GCC 和 G++ 为最新版本
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100

# 安装 ARM 交叉编译工具链
sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
sudo apt install -y gcc-arm-linux-gnueabi g++-arm-linux-gnueabi
sudo apt install -y gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf

# 安装本地 binutils 工具 (x86 架构)
sudo apt install -y binutils

# 安装 ARM 交叉编译工具链的 binutils
sudo apt install -y binutils-aarch64-linux-gnu binutils-arm-linux-gnueabi binutils-arm-linux-gnueabihf

# 安装调试和开发工具
sudo apt install -y gdb-multiarch valgrind strace ltrace
