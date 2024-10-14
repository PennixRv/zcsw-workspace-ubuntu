#!/bin/bash

sudo apt update && sudo apt upgrade -y

sudo apt install -y build-essential curl

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

source $HOME/.cargo/env

grep -qxF 'source "$HOME/.cargo/env"' ~/.bashrc || echo 'source "$HOME/.cargo/env"' >> ~/.zshrc

source ~/.zshrc