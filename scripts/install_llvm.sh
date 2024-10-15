#!/bin/bash

sudo apt-get update && sudo  apt install -y lsb-release wget software-properties-common gnupg
cd /tmp
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
sudo ./llvm.sh 20 all
