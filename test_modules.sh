#!/bin/bash

echo "测试 Lebit.sh 模块路径功能"
echo "==========================="

# 测试所有模块路径
modules=("system" "docker" "dev" "tools" "mining")

for module in "${modules[@]}"; do
    echo -e "\n测试 $module 模块:"
    echo "命令: curl --proto '=https' --tlsv1.2 -sSf https://lebit.sh/$module -H 'User-Agent: curl/7.88.1' | head -10"
    echo "---"
    curl --proto '=https' --tlsv1.2 -sSf "https://lebit.sh/$module?t=$(date +%s)" -H "User-Agent: curl/7.88.1" | head -10
    echo -e "\n---"
done

echo -e "\n测试主安装路径:"
echo "命令: curl --proto '=https' --tlsv1.2 -sSf https://lebit.sh/install | head -10"
curl --proto '=https' --tlsv1.2 -sSf "https://lebit.sh/install?t=$(date +%s)" -H "User-Agent: curl/7.88.1" | head -10