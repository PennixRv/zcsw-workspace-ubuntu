#!/bin/bash

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

# 安装 VS Code Server
curl -fsSL https://update.code.visualstudio.com/latest/server-linux-x64/stable -o /tmp/vscode-server-linux-x64.tar.gz
mkdir -p "$HOME/.vscode-server"
tar -xzf /tmp/vscode-server-linux-x64.tar.gz -C "$HOME/.vscode-server" --strip-components=1
rm /tmp/vscode-server-linux-x64.tar.gz

# 设置 VS Code Server 文件夹权限
chown -R "$USER:$USER" "$HOME/.vscode-server"

# 安装扩展示例（可选）
# 使用官方 cli 安装 extensions，假设 VS Code Server 的二进制文件在 $HOME/.vscode-server/bin/ 中
VSCODE_BIN_PATH="$HOME/.vscode-server/bin/$(ls $HOME/.vscode-server/bin/)"
su - $USER -c "$VSCODE_BIN_PATH --install-extension ms-python.python"

echo "VS Code Server and SSH are set up."
