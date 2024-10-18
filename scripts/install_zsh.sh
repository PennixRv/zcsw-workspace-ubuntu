#!/bin/bash

if [ "$(id -u)" -eq 0 ]; then
    echo "This script should not be run as root. Please run it as your regular user."
    exit 1
fi

sudo apt install -y zsh git

zsh << 'EOF'

# Set up Oh My Zsh installation script URL
OMZ_INSTALL_SCRIPT="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
REMOTE_URL="https://github.com/ohmyzsh/ohmyzsh.git"

# Adjust URLs if PROXY_ENABLED is set to false
if [[ "$PROXY_ENABLED" == "false" ]]; then
    OMZ_INSTALL_SCRIPT="https://gitdl.cn/$OMZ_INSTALL_SCRIPT"
    REMOTE_URL="https://gitdl.cn/$REMOTE_URL"
fi

# Download and run the Oh My Zsh install script
cd /tmp
wget $OMZ_INSTALL_SCRIPT
chmod a+x ./install.sh
CHSH=yes RUNZSH=yes KEEP_ZSHRC=no REMOTE=$REMOTE_URL ./install.sh

# Set repository prefix and adjust if PROXY_ENABLED is set to false
REPO_PREFIX="https://github.com"
[[ "$PROXY_ENABLED" == "false" ]] && REPO_PREFIX="https://gitdl.cn/$REPO_PREFIX"

# Clone necessary repositories for themes and plugins
THEMES_DIR=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes
PLUGINS_DIR=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins

git clone --depth=1 "$REPO_PREFIX/romkatv/powerlevel10k.git" "$THEMES_DIR/powerlevel10k"
git clone "$REPO_PREFIX/zsh-users/zsh-autosuggestions" "$PLUGINS_DIR/zsh-autosuggestions"
git clone "$REPO_PREFIX/zsh-users/zsh-syntax-highlighting.git" "$PLUGINS_DIR/zsh-syntax-highlighting"
git clone "$REPO_PREFIX/zsh-users/zsh-completions.git" "$PLUGINS_DIR/zsh-completions"
git clone "$REPO_PREFIX/zsh-users/zsh-history-substring-search.git" "$PLUGINS_DIR/zsh-history-substring-search"

# Update .zshrc for themes and plugins
sed -i 's#ZSH_THEME=".*"#ZSH_THEME="powerlevel10k/powerlevel10k"#' ~/.zshrc
sed -i 's#plugins=(git)#plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search)#' ~/.zshrc

# Disable update prompt and ensure .p10k.zsh is sourced if present
echo 'DISABLE_UPDATE_PROMPT=true' >> ~/.zshrc
sudo cp /usr/local/bin/pre_configured_scripts/.p10k.zsh ~
echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc
source ~/.zshrc || echo "Unable to source ~/.zshrc, please open a new terminal or manually source it."

EOF