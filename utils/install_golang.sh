#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 函数：输出彩色日志
log() {
    local color=\$1
    local message=\$2
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

# 函数：输出错误日志并退出
error_exit() {
    log "${RED}" "错误: \$1" >&2
    exit 1
}

# 函数：卸载已存在的 Golang
uninstall_existing_golang() {
    if command -v go &> /dev/null; then
        log "${YELLOW}" "检测到已安装的 Golang，正在卸载..."
        sudo rm -rf /usr/local/go
        sudo rm -f /etc/profile.d/golang.sh
        log "${YELLOW}" "已卸载旧版 Golang"
    fi
}

# 询问用户是否继续安装
read -p "是否要在本机安装/更新 Golang? (yes/no): " answer
if [[ ! $answer =~ ^[Yy][Ee][Ss]$ ]]; then
    log "${YELLOW}" "用户取消安装，退出脚本。"
    exit 0
fi

# 开始安装
log "${GREEN}" "开始安装 Golang..."

# 卸载已存在的 Golang
uninstall_existing_golang

# 获取最新的 Golang 稳定版本
log "${GREEN}" "正在获取最新的 Golang 版本..."
GO_VERSION=$(curl -s https://golang.org/VERSION?m=text)
[[ -z "$GO_VERSION" ]] && error_exit "无法获取 Golang 最新版本"
log "${GREEN}" "检测到最新的 Golang 版本: $GO_VERSION"

# 确定操作系统和架构
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv*) ARCH="armv6l" ;;
esac

# 下载 URL
DOWNLOAD_URL="https://golang.org/dl/${GO_VERSION}.${OS}-${ARCH}.tar.gz"

# 检测包管理器
log "${GREEN}" "正在检测包管理器..."
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt-get"
    INSTALL_CMD="sudo apt-get update && sudo apt-get install -y"
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    INSTALL_CMD="sudo yum install -y"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="sudo dnf install -y"
else
    error_exit "未知的包管理器，无法继续安装"
fi

log "${GREEN}" "检测到包管理器: $PKG_MANAGER"

# 安装必要的工具
log "${GREEN}" "安装必要的工具..."
$INSTALL_CMD curl tar || error_exit "无法安装必要的工具"

# 下载 Golang
log "${GREEN}" "下载 Golang..."
curl -LO "$DOWNLOAD_URL" || error_exit "下载 Golang 失败"

# 解压并安装 Golang
log "${GREEN}" "安装 Golang..."
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "${GO_VERSION}.${OS}-${ARCH}.tar.gz" || error_exit "解压 Golang 失败"
rm "${GO_VERSION}.${OS}-${ARCH}.tar.gz"

# 设置环境变量
log "${GREEN}" "设置环境变量..."
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh
source /etc/profile.d/golang.sh

# 验证安装
if go version &> /dev/null; then
    GO_INSTALLED_VERSION=$(go version | awk '{print \$3}')
    log "${GREEN}" "Golang 安装成功，版本: $GO_INSTALLED_VERSION"
else
    error_exit "Golang 安装失败或环境变量设置不正确"
fi

log "${GREEN}" "Golang 安装完成"