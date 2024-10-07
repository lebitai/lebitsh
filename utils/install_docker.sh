#!/bin/bash

# 确保脚本以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo "请以 root 权限运行此脚本"
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
    echo "无法检测操作系统"
    exit 1
fi

# 安装 Docker 的函数
install_docker() {
    # 启动 Docker
    systemctl start docker
    # 设置 Docker 开机自启
    systemctl enable docker
    # 验证 Docker 是否安装成功
    if ! command -v docker &> /dev/null; then
        echo "Docker 安装失败"
        exit 1
    fi
    # 将当前用户添加到 docker 用户组
    usermod -aG docker $SUDO_USER
    echo "Docker 安装成功！"
    echo "请注销并重新登录，或重启系统以应用更改。"
    echo "您可以运行 'docker --version' 来验证安装。"
}

# 根据不同的操作系统安装 Docker
case $OS in
    "Ubuntu")
        echo "检测到 Ubuntu 系统，版本: $VER"
        # 更新包索引
        apt-get update
        # 安装必要的依赖
        apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
        # 添加 Docker 的官方 GPG 密钥
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        # 设置稳定版仓库
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        # 再次更新包索引
        apt-get update
        # 安装 Docker Engine
        apt-get install -y docker-ce docker-ce-cli containerd.io
        install_docker
        ;;
    "CentOS Linux")
        echo "检测到 CentOS 系统，版本: $VER"
        # 安装必要的依赖
        yum install -y yum-utils device-mapper-persistent-data lvm2
        # 设置稳定版仓库
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        # 安装 Docker Engine
        yum install -y docker-ce docker-ce-cli containerd.io
        install_docker
        ;;
    *)
        echo "不支持的操作系统: $OS"
        exit 1
        ;;
esac
