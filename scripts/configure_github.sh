#!/bin/bash

git config --global user.name "penn"
git config --global user.email "pennaliflake@gmail.com"
git config --global core.editor "vim"
git config --global --add oh-my-zsh.hide-dirty 1

# 更新系统并安装OpenSSH和GitHub CLI
sudo apt update
sudo apt install openssh-client gh -y

# 生成SSH密钥，邮箱设置为你的电子邮件地址
ssh-keygen -t ed25519 -C "pennaliflake@gmail.com" -f ~/.ssh/github_access -N ""

# 启动ssh-agent并添加密钥
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github_access

# 使用GitHub CLI登录
echo "" | gh auth login --with-token

# 将SSH公钥添加到GitHub账户
gh ssh-key add ~/.ssh/github_access.pub -t "GitHub Access Key"
