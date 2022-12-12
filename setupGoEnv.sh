#!/bin/bash

leftChar="⇢ |・・・・・・ "
rightChar=" ・・・・・・ | ⇠"

echo " $leftChar Starting to download Golang packages from official website at $(date) $rightChar "
wget https://go.dev/dl/go1.19.4.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.19.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

source "$HOME"/.bashrc

sleep 10
wait $!

echo "$leftChar Starting to download Rust packages from official website at $(date) $rightChar "
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME"/.bashrc

echo " $leftChar Checking whether all the packages installed? $rightChar "
go version
cargo version
rustc version
