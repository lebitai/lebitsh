#!/bin/bash

# 部署脚本

set -e

# 检查 .env 文件是否存在
if [ ! -f ".env" ]; then
    echo "错误: .env 文件不存在。请创建 .env 文件并添加 CLOUDFLARE_ACCOUNT_ID 和 CLOUDFLARE_API_TOKEN"
    exit 1
fi

# 加载环境变量
export $(cat .env | xargs)

# 检查必要的环境变量
if [ -z "$CLOUDFLARE_ACCOUNT_ID" ] || [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo "错误: 请在 .env 文件中设置 CLOUDFLARE_ACCOUNT_ID 和 CLOUDFLARE_API_TOKEN"
    exit 1
fi

# 部署到 Cloudflare Workers
echo "正在部署到 Cloudflare Workers..."
npx wrangler deploy

echo "部署完成!"