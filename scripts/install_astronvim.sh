#!/bin/bash

sudo apt update && sudo apt upgrade -y
sudo apt-get install -y curl
sudo add-apt-repository -y ppa:neovim-ppa/stable
sudo apt update
sudo apt install -y neovim

curl -fsSL https://deb.nodesource.com/setup_22.x -o nodesource_setup.sh
sudo -E bash nodesource_setup.sh
sudo apt-get install -y nodejs
rm -rf nodesource_setup.sh

sudo npm config set proxy $http_proxy
sudo npm config set https-proxy $https_proxy

sudo apt install -y xclip xsel

cargo install tree-sitter-cli
cargo install ripgrep
cargo install bottom

go install github.com/jesseduffield/lazygit@latest
go install github.com/dundee/gdu/v5/cmd/gdu@latest

sudo apt install -y python3 python3-pip

pip3 install pynvim --break-system-packages

sudo npm install -g neovim

grep -qxF 'export NVIM_TUI_ENABLE_TRUE_COLOR=1' ~/.zshrc || echo 'export NVIM_TUI_ENABLE_TRUE_COLOR=1' >> ~/.zshrc

source ~/.zshrc

mv ~/.config/nvim ~/.config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
mv ~/.local/state/nvim ~/.local/state/nvim.bak
mv ~/.cache/nvim ~/.cache/nvim.bak
git clone --depth 1 https://github.com/AstroNvim/template ~/.config/nvim
rm -rf ~/.config/nvim/.git