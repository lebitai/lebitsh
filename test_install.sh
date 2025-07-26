#!/bin/bash

echo "测试 Cloudflare Worker 安装脚本功能"
echo "=================================="

# 测试 1: 使用 curl 访问根路径
echo -e "\n1. 测试 curl 访问根路径 (/):"
echo "命令: curl -H 'User-Agent: curl/7.64.1' http://localhost:8787/"
echo "预期: 应该返回 bash 安装脚本"
echo "---"

# 测试 2: 使用 curl 访问 /install 路径
echo -e "\n2. 测试 curl 访问 /install 路径:"
echo "命令: curl -H 'User-Agent: curl/7.64.1' http://localhost:8787/install"
echo "预期: 应该返回 bash 安装脚本"
echo "---"

# 测试 3: 使用浏览器 User-Agent 访问根路径
echo -e "\n3. 测试浏览器访问根路径 (/):"
echo "命令: curl -H 'User-Agent: Mozilla/5.0' http://localhost:8787/"
echo "预期: 应该返回网站 HTML 内容"
echo "---"

# 测试 4: 使用浏览器 User-Agent 访问 /install 路径
echo -e "\n4. 测试浏览器访问 /install 路径:"
echo "命令: curl -H 'User-Agent: Mozilla/5.0' http://localhost:8787/install"
echo "预期: 应该返回 bash 脚本作为下载文件"
echo "---"

# 测试 5: 真实的安装命令
echo -e "\n5. 测试真实的安装命令:"
echo "命令: curl --proto '=https' --tlsv1.2 -sSf localhost:8787/install | sh"
echo "预期: 应该能够下载并执行安装脚本"
echo "---"

echo -e "\n注意: 在部署到 Cloudflare 后，将 localhost:8787 替换为 lebit.sh"