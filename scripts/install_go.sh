#!/bin/bash

GO_VERSION="1.23.2"

wget https://golang.google.cn/dl/go$GO_VERSION.linux-amd64.tar.gz

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
