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
    echo -e "${RED}错误: \$1${NC}" >&2
    exit 1
}

# 函数：卸载已存在的 Golang
uninstall_existing_golang() {
    if command -v go &> /dev/null; then
        echo -e "${YELLOW}检测到已安装的 Golang，正在卸载...${NC}"
        if sudo -v &> /dev/null; then
            sudo rm -rf /usr/local/go
            sudo rm -f /etc/profile.d/golang.sh
            echo -e "${YELLOW}已卸载旧版 Golang${NC}"
        else
            error_exit "当前用户没有 sudo 权限，无法卸载已存在的 Golang"
        fi
    fi
}

# 函数：安装 Golang
install_golang() {
    # 获取最新的 Golang 稳定版本
    echo -e "${GREEN}正在获取最新的 Golang 版本...${NC}"
    if ! command -v curl &> /dev/null; then
        error_exit "curl 命令不存在，无法获取 Golang 最新版本"
    fi
    if ! command -v grep &> /dev/null; then
        error_exit "grep 命令不存在，无法获取 Golang 最新版本"
    fi
    GO_VERSION=$(curl -sSL https://go.dev/VERSION?m=text | grep -o 'go[0-9.]*')
    [[ -z "$GO_VERSION" ]] && error_exit "无法获取 Golang 最新版本"
    echo -e "${GREEN}检测到最新的 Golang 版本: $GO_VERSION${NC}"

    # 确定操作系统和架构
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv*) ARCH="armv6l" ;;
        *) error_exit "不支持的架构: $ARCH" ;;
    esac

    # 下载 URL
    DOWNLOAD_URL="https://golang.org/dl/${GO_VERSION}.${OS}-${ARCH}.tar.gz"
    echo "Golang URL is : ${DOWNLOAD_URL}"

    # 检测包管理器
    echo -e "${GREEN}正在检测包管理器...${NC}"
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt-get"
        echo -e "${GREEN}安装必要的工具:curl,tar...${NC}"
        sudo apt-get update && sudo apt-get install -y curl tar
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        echo -e "${GREEN}安装必要的工具:curl,tar...${NC}"
        sudo yum install -y curl tar
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        echo -e "${GREEN}安装必要的工具:curl,tar...${NC}"
        sudo dnf install -y curl tar
    else
        error_exit "未知的包管理器，无法继续安装"
    fi

    # 下载 Golang
    echo -e "${GREEN}下载 Golang...${NC}"
    curl -LO "$DOWNLOAD_URL" || error_exit "下载 Golang 失败"

    # 解压并安装 Golang
    echo -e "${GREEN}安装 Golang...${NC}"
    if sudo -v &> /dev/null; then
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "${GO_VERSION}.${OS}-${ARCH}.tar.gz" || error_exit "解压 Golang 失败"
        rm "${GO_VERSION}.${OS}-${ARCH}.tar.gz"
    else
        error_exit "当前用户没有 sudo 权限，无法安装 Golang"
    fi

    # 设置环境变量
    echo -e "${GREEN}设置环境变量...${NC}"
    if [ -w ~/.bashrc ]; then
        echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
        source ~/.bashrc
    else
        error_exit "当前用户没有写入 ~/.bashrc 文件的权限，无法设置环境变量"
    fi

    # 验证安装
    echo -e "${GREEN}验证 Golang 安装...${NC}"
    if go version &> /dev/null; then
        GO_INSTALLED_VERSION=$(go version | awk '{print \$3}')
        echo -e "${GREEN}Golang 安装成功，版本: $GO_INSTALLED_VERSION${NC}"
    else
        error_exit "Golang 安装失败或环境变量设置不正确"
    fi

    echo -e "${GREEN}Golang 安装完成${NC}"
}

# 主函数
main() {
    # 询问用户是否继续安装
    read -p "是否要在本机安装/更新 Golang? (yes/no): " answer
    if [[ ! $answer =~ ^[Yy][Ee][Ss]$ ]]; then
        echo -e "${YELLOW}用户取消安装，退出脚本。${NC}"
        exit 0
    fi

    # 开始安装
    echo -e "${GREEN}开始安装 Golang...${NC}"

    # 卸载已存在的 Golang
    uninstall_existing_golang

    # 安装 Golang
    install_golang
}

# 调用主函数
main