#!/bin/bash

# 设置 Go 版本号
GO_VERSION="1.23.2"

# 下载指定版本的 Go 压缩包
wget https://golang.google.cn/dl/go$GO_VERSION.linux-amd64.tar.gz

# 解压压缩包
tar -xvf go$GO_VERSION.linux-amd64.tar.gz

sudo mv go /usr/local

rm go$GO_VERSION.linux-amd64.tar.gz

if ! grep -q "export GOROOT=/usr/local/go" ~/.zshrc; then
    echo 'export GOROOT=/usr/local/go' >> ~/.zshrc
    echo 'export GOPATH=$HOME/go' >> ~/.zshrc
    echo 'export PATH=$GOPATH/bin:$GOROOT/bin:$PATH' >> ~/.zshrc
    echo 'export GOPROXY=https://mirrors.aliyun.com/goproxy/,direct' >> ~/.zshrc
fi
source ~/.zshrc

go env -w GO111MODULE=on

