#!/bin/bash

leftChar="⇢ |・・・・・・ "
rightChar=" ・・・・・・ | ⇠"

echo " $leftChar Starting to download Golang packages from official website at $(date) $rightChar "
wget https://go.dev/dl/go1.19.4.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.19.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

echo " $leftChar Checking whether it's installed? $rightChar "
go version
