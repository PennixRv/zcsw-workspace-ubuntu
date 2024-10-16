#!/bin/bash

# Check if the proxy is enabled
if [ "$PROXY_ENABLED" = "true" ]; then
    # Using the default llvm.sh from apt.llvm.org
    BASE_URL="http://apt.llvm.org"
    LLVM_SCRIPT_URL="https://apt.llvm.org/llvm.sh"
else
    # Using the llvm.sh from Tsinghua University mirror
    BASE_URL="https://mirrors.tuna.tsinghua.edu.cn/llvm-apt"
    LLVM_SCRIPT_URL="https://mirrors.tuna.tsinghua.edu.cn/llvm-apt/llvm.sh"
fi

sudo apt-get update && sudo apt install -y lsb-release wget software-properties-common gnupg
cd /tmp
wget $LLVM_SCRIPT_URL
chmod +x llvm.sh
sudo ./llvm.sh 20 all -m $BASE_URL
