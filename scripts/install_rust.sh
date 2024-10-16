SHELL_RC="$HOME/.bashrc"
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ "$PROXY_ENABLED" = "false" ]; then
    echo "export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup" >> "$SHELL_RC"
    echo "export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup" >> "$SHELL_RC"
fi
source "$SHELL_RC"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y

source "$HOME/.cargo/env"
grep -qxF 'source "$HOME/.cargo/env"' "$SHELL_RC" || echo 'source "$HOME/.cargo/env"' >> "$SHELL_RC"

mkdir -p $HOME/.cargo
cat << EOF > $HOME/.cargo/config
[source.crates-io]
registry = "https://github.com/rust-lang/crates.io-index"
replace-with = 'tuna'

[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"

[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"

[source.sjtu]
registry = "https://mirrors.sjtug.sjtu.edu.cn/git/crates.io-index"

[source.rustcc]
registry = "git://crates.rustcc.cn/crates.io-index"
EOF

source "$SHELL_RC"
