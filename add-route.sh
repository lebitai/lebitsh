#!/bin/bash

# 从 .env 文件加载环境变量
source .env

# Worker 名称
WORKER_NAME="lebitsh"

# 自定义域
CUSTOM_DOMAIN="lebit.sh"

# Cloudflare API 端点
API_ENDPOINT="https://api.cloudflare.com/client/v4"

# 添加路由的函数
add_route() {
  local zone_id=$CLOUDFLARE_ZONE_ID
  local route_pattern="$CUSTOM_DOMAIN/*"
  
  echo "Adding route: $route_pattern"
  
  # 使用 curl 添加路由
  response=$(curl -s -X POST "$API_ENDPOINT/zones/$zone_id/workers/routes" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{\"pattern\":\"$route_pattern\",\"script\":\"$WORKER_NAME\"}")
  
  # 检查响应
  if echo "$response" | grep -q '"success":true'; then
    echo "Route added successfully"
  else
    echo "Failed to add route"
    echo "Response: $response"
  fi
}

# 执行函数
add_route
