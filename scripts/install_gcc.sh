#!/bin/bash

sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

sudo add-apt-repository ppa:ubuntu-toolchain-r/test -y
sudo apt update

sudo apt install -y gcc-14 g++-14 make build-essential libgcc-14-dev

sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100

sudo apt install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
sudo apt install -y gcc-arm-linux-gnueabi g++-arm-linux-gnueabi
sudo apt install -y gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf

sudo apt install -y binutils

sudo apt install -y binutils-aarch64-linux-gnu binutils-arm-linux-gnueabi binutils-arm-linux-gnueabihf

sudo apt install -y gdb-multiarch valgrind strace ltrace
