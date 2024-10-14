#!/bin/bash

# 确保传入 VS Code Commit ID
if [ -z "$CODE_COMMITID" ]; then
    echo "Error: VS Code commit ID is not provided."
    exit 1
fi

# 更新软件包和安装 OpenSSH 服务器
apt-get update
apt-get install -y openssh-server

# 启动 SSH 服务并设置开机自启
systemctl enable --now ssh

# 循环检查 SSH 服务是否已经启动
while ! systemctl is-active --quiet ssh; do
    echo "Waiting for SSH service to start..."
    sleep 1
done

# 设置 SSH 以允许密码认证
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart ssh

VSCODE_SERVER_URL="https://vscode.download.prss.microsoft.com/dbazure/download/stable/${CODE_COMMITID}/vscode-server-linux-x64.tar.gz"
mkdir -p "$HOME/.vscode-server/bin/$CODE_COMMITID"
rm -rf "$HOME/.vscode-server/bin/$CODE_COMMITID/*"
echo "Downloading VS Code Server..."
curl -L "$VSCODE_SERVER_URL" -o "$HOME/.vscode-server/bin/$CODE_COMMITID/vscode-server-linux-x64.tar.gz"
cd "$HOME/.vscode-server/bin/$CODE_COMMITID"
echo "Installing VS Code Server..."
tar -xvzf vscode-server-linux-x64.tar.gz --strip-components=1
rm vscode-server-linux-x64.tar.gz
