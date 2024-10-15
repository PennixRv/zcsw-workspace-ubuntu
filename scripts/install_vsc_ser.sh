#!/bin/bash

if [ -z "$CODE_COMMITID" ]; then
    echo "Error: VS Code commit ID is not provided."
    exit 1
fi

apt-get update
apt-get install -y openssh-server

systemctl enable --now ssh

while ! systemctl is-active --quiet ssh; do
    echo "Waiting for SSH service to start..."
    sleep 1
done

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