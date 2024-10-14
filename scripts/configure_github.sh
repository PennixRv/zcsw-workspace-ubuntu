#!/bin/bash

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GitHub token is not provided."
    exit 1
fi

git config --global user.name "penn"
git config --global user.email "pennaliflake@gmail.com"
git config --global core.editor "vim"
git config --global --add oh-my-zsh.hide-dirty 1

sudo apt update
sudo apt install openssh-client gh -y

ssh-keygen -t ed25519 -C "pennaliflake@gmail.com" -f ~/.ssh/github_access -N ""

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github_access

echo "$GH_TOKEN" | gh auth login --with-token

gh ssh-key add ~/.ssh/github_access.pub -t "GitHub Access Key"
