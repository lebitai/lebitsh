#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 函数：显示品牌
show_brand() {
    clear
    echo -e "${WHITE}"
    echo "
 _      _____ ____ ___ _____   ____  _   _ 
| |    | ____| __ )_ _|_   _| / ___|| | | |
| |    |  _| |  _ \| |  | |   \___ \| |_| |
| |___ | |___| |_) | |  | |    ___) |  _  |
|_____|_____|____/___| |_|   |____/|_| |_|
                                           
            https://lebit.sh
"
    echo -e "${NC}"
}

# 函数：输出彩色日志
log() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

# 函数：输出错误日志并退出
error_exit() {
    echo -e "${RED}错误: $1${NC}" >&2
    exit 1
}

# 函数：卸载已存在的 Rust
uninstall_existing_rust() {
    if command -v rustc &> /dev/null; then
        echo -e "${YELLOW}检测到已安装的 Rust，正在卸载...${NC}"
        rustup self uninstall -y
        echo -e "${YELLOW}已卸载旧版 Rust${NC}"
    fi
}

# 函数：安装 Rust
install_rust() {
    # 检查必要的工具
    echo -e "${GREEN}检查必要的工具...${NC}"
    if ! command -v curl &> /dev/null; then
        error_exit "curl 命令不存在，请先安装 curl"
    fi

    # 下载并运行 Rust 安装脚本
    echo -e "${GREEN}下载并运行 Rust 安装脚本...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    # 设置环境变量
    echo -e "${GREEN}设置环境变量...${NC}"
    if [ -w ~/.bashrc ]; then
        if ! grep -q "source \$HOME/.cargo/env" ~/.bashrc; then
            echo "source \$HOME/.cargo/env" >> ~/.bashrc
        fi
        source $HOME/.cargo/env
    else
        error_exit "当前用户没有写入 ~/.bashrc 文件的权限，无法设置环境变量"
    fi

    # 验证安装
    echo -e "${GREEN}验证 Rust 安装...${NC}"
    if rustc --version &> /dev/null; then
        RUST_VERSION=$(rustc --version | awk '{print $2}')
        echo -e "${GREEN}Rust 安装成功，版本: $RUST_VERSION${NC}"
    else
        error_exit "Rust 安装失败或环境变量设置不正确"
    fi

    echo -e "${GREEN}Rust 安装完成${NC}"
    echo -e "${YELLOW}请运行 'source ~/.bashrc' 或重新登录以确保环境变量在所有 shell 会话中生效${NC}"
}

# 主函数
main() {
    show_brand

    # 询问用户是否继续安装
    read -p "是否要在本机安装/更新 Rust? (yes/no): " answer
    if ! echo "$answer" | grep -iq "^y"; then
        echo -e "${YELLOW}用户取消安装，退出脚本。${NC}"
        exit 0
    fi

    # 开始安装
    echo -e "${GREEN}开始安装 Rust...${NC}"

    # 卸载已存在的 Rust
    uninstall_existing_rust

    # 安装 Rust
    install_rust
}

# 调用主函数
main
