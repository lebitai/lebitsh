#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 进度条函数
progress_bar() {
    local duration=$1
    local steps=$2
    local step_duration=$(echo "scale=2; $duration/$steps" | bc)
    for i in $(seq 1 $steps); do
        echo -ne "\r[${YELLOW}"
        for j in $(seq 1 $i); do echo -n "#"; done
        for j in $(seq $i $steps); do echo -n " "; done
        echo -n "${NC}] $((i*100/steps))%"
        sleep $step_duration
    done
    echo
}

# 确保脚本以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请以 root 权限运行此脚本${NC}"
    exit 1
fi

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
else
    echo -e "${RED}无法检测操作系统${NC}"
    exit 1
fi

# 安装 Docker 的函数
install_docker() {
    echo -e "${YELLOW}正在安装 Docker...${NC}"
    progress_bar 10 20

    # 启动 Docker
    systemctl start docker
    # 设置 Docker 开机自启
    systemctl enable docker
    # 验证 Docker 是否安装成功
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker 安装失败${NC}"
        exit 1
    fi
    # 将当前用户添加到 docker 用户组
    usermod -aG docker $SUDO_USER
    echo -e "${GREEN}Docker 安装成功！${NC}"
    echo -e "${YELLOW}请注销并重新登录，或重启系统以应用更改。${NC}"
    echo -e "${YELLOW}您可以运行 'docker --version' 来验证安装。${NC}"
}

# 根据不同的操作系统安装 Docker
case $OS in
    "Ubuntu")
        echo -e "${YELLOW}检测到 Ubuntu 系统，版本: $VER${NC}"
        echo -e "${YELLOW}正在更新包索引...${NC}"
        apt-get update > /dev/null 2>&1
        progress_bar 5 10
        echo -e "${YELLOW}正在安装必要的依赖...${NC}"
        apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release > /dev/null 2>&1
        progress_bar 5 10
        echo -e "${YELLOW}添加 Docker 的官方 GPG 密钥...${NC}"
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1
        progress_bar 3 10
        echo -e "${YELLOW}设置稳定版仓库...${NC}"
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        progress_bar 2 10
        echo -e "${YELLOW}再次更新包索引...${NC}"
        apt-get update > /dev/null 2>&1
        progress_bar 5 10
        install_docker
        ;;
    "CentOS Linux")
        echo -e "${YELLOW}检测到 CentOS 系统，版本: $VER${NC}"
        echo -e "${YELLOW}正在安装必要的依赖...${NC}"
        yum install -y yum-utils device-mapper-persistent-data lvm2 > /dev/null 2>&1
        progress_bar 10 20
        echo -e "${YELLOW}设置稳定版仓库...${NC}"
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1
        progress_bar 5 10
        install_docker
        ;;
    *)
        echo -e "${RED}不支持的操作系统: $OS${NC}"
        exit 1
        ;;
esac
