#!/bin/bash

if [ "$(id -u)" -eq 0 ]; then
    echo "This script should not be run as root. Please run it as your regular user."
    exit 1
fi

sudo apt update && sudo apt install -y zsh


OMZ_INSTALL_SCRIPT="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
[[ "$PROXY_ENABLED" == "false" ]] && OMZ_INSTALL_SCRIPT="https://ghproxy.net/$OMZ_INSTALL_SCRIPT"
sh -c "$(curl -fsSL $OMZ_INSTALL_SCRIPT)" "" --unattended

sudo chsh -s $(which zsh)

# Define repository prefix based on proxy usage
REPO_PREFIX="https://github.com"
[[ "$PROXY_ENABLED" == "false" ]] && REPO_PREFIX="https://ghproxy.net/$REPO_PREFIX"

# Install Zsh themes and plugins
THEMES_DIR=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes
PLUGINS_DIR=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins

git clone --depth=1 "$REPO_PREFIX/romkatv/powerlevel10k.git" "$THEMES_DIR/powerlevel10k"
git clone "$REPO_PREFIX/zsh-users/zsh-autosuggestions" "$PLUGINS_DIR/zsh-autosuggestions"
git clone "$REPO_PREFIX/zsh-users/zsh-syntax-highlighting.git" "$PLUGINS_DIR/zsh-syntax-highlighting"
git clone "$REPO_PREFIX/zsh-users/zsh-completions.git" "$PLUGINS_DIR/zsh-completions"
git clone "$REPO_PREFIX/zsh-users/zsh-history-substring-search.git" "$PLUGINS_DIR/zsh-history-substring-search"

# Update .zshrc configuration
sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search)/' ~/.zshrc

# Source the configuration if .zshrc exists
echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc
source ~/.zshrc || echo "Unable to source ~/.zshrc, please open a new terminal or manually source it."