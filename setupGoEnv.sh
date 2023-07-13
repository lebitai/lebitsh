#!/bin/bash

leftChar="⇢ |・・・・・・ "
rightChar=" ・・・・・・ | ⇠"

echo " $leftChar Starting to download Golang packages from official website at $(date) $rightChar "
wget https://go.dev/dl/go1.20.5.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

source $HOME/.bashrc
source $HOME/.profile

sleep 10
wait $!

echo "$leftChar Starting to download Rust packages from official website at $(date) $rightChar "
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

source "$HOME/.cargo/env"
echo " $leftChar Starting to download Nodejs package and install it at $(date) $rightChar"
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo apt install mesa-opencl-icd ocl-icd-opencl-dev gcc git bzr jq pkg-config curl clang build-essential hwloc libhwloc-dev wget -y

echo " $leftChar Checking whether all the packages installed? $rightChar "
go version
cargo version
rustc --version
node --version
