SHELL_RC="$HOME/.bashrc"
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ "$PROXY_ENABLED" = "false" ]; then
    echo 'export RUSTUP_DIST_SERVER="https://rsproxy.cn"' >> $SHELL_RC
    echo 'export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"' >> $SHELL_RC
fi
source $SHELL_RC
curl --proto '=https' --tlsv1.2 -sSf https://rsproxy.cn/rustup-init.sh | bash -s -- -y

source "$HOME/.cargo/env"
grep -qxF 'source "$HOME/.cargo/env"' $SHELL_RC || echo 'source "$HOME/.cargo/env"' >> $SHELL_RC

mkdir -p $HOME/.cargo
cat << EOF > $HOME/.cargo/config
[source.crates-io]
replace-with = 'rsproxy-sparse'
[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"
[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"
[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"
[net]
git-fetch-with-cli = true
EOF

source $SHELL_RC
