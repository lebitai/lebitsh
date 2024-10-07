#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 函数: 输出错误信息并退出
error_exit() {
    echo -e "${RED}错误: $1${NC}" >&2
    exit 1
}

# 函数: 输出成功信息
success_msg() {
    echo -e "${GREEN}$1${NC}"
}

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    error_exit "请以 root 权限运行此脚本"
fi

# 更新包列表
echo "正在更新包列表..."
apt update || error_exit "无法更新包列表"

# 安装 SQLite3
echo "正在安装 SQLite3..."
apt install -y sqlite3 || error_exit "无法安装 SQLite3"

# 验证安装
if command -v sqlite3 &> /dev/null; then
    VERSION=$(sqlite3 --version)
    success_msg "SQLite3 安装成功! 版本: $VERSION"
else
    error_exit "SQLite3 安装失败"
fi

# 显示基本用法
echo "
SQLite3 基本用法:
1. 创建/打开数据库: sqlite3 database.db
2. 在 SQLite 提示符下, 您可以输入 SQL 命令
3. 退出 SQLite: .quit

更多信息请参考 SQLite 文档。"

success_msg "安装脚本执行完毕"
