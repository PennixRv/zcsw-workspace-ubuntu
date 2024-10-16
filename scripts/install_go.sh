GO_VERSION="1.23.2"
cd /tmp

SHELL_RC="$HOME/.bashrc"
if [[ $SHELL =~ .*zsh.* ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ $SHELL =~ .*bash.* ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ "$PROXY_ENABLED" = "false" ]; then
    GO_URL="https://studygolang.com/dl/golang/go$GO_VERSION.linux-amd64.tar.gz"
else
    GO_URL="https://golang.google.cn/dl/go$GO_VERSION.linux-amd64.tar.gz"
fi

wget $GO_URL

tar -xvf go$GO_VERSION.linux-amd64.tar.gz
sudo mv go /usr/local
rm go$GO_VERSION.linux-amd64.tar.gz

if ! grep -q "export GOROOT=/usr/local/go" $SHELL_RC; then
    echo 'export GOROOT=/usr/local/go' >> $SHELL_RC
    echo 'export GOPATH=$HOME/go' >> $SHELL_RC
    echo 'export PATH=$GOPATH/bin:$GOROOT/bin:$PATH' >> $SHELL_RC
    if [ "$PROXY_ENABLED" = "false" ]; then
        echo 'export GOPROXY=https://mirrors.aliyun.com/goproxy/,direct' >> $SHELL_RC
    fi
fi

source $SHELL_RC

go env -w GO111MODULE=on
