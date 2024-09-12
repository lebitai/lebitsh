#!/bin/bash

# 定义颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 错误处理函数
error_exit() {
    echo -e "${RED}错误: $1${NC}" >&2
    exit 1
}

# 警告函数
warning() {
    echo -e "${YELLOW}警告: $1${NC}"
}

# 成功消息函数
success() {
    echo -e "${GREEN}$1${NC}"
}

# 检查 curl 是否已安装
if ! command -v curl &> /dev/null; then
    warning "curl 未安装. 正在尝试安装..."
    sudo apt update && sudo apt install -y curl || error_exit "无法安装 curl"
fi

# 获取最新的 NVM 版本
echo "正在获取最新的 NVM 版本..."
NVM_LATEST=$(curl -sL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
[ -z "$NVM_LATEST" ] && error_exit "无法获取最新的 NVM 版本"
success "检测到最新的 NVM 版本: $NVM_LATEST"

# 下载并运行 NVM 安装脚本
echo "正在下载并安装 NVM..."
curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_LATEST/install.sh" | bash || error_exit "NVM 安装失败"

# 设置 NVM 环境变量
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # 加载 NVM
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # 加载 NVM bash_completion

# 验证安装
if command -v nvm &> /dev/null; then
    success "NVM 已成功安装!"
    echo -e "NVM 版本: $(nvm --version)"
    
    # 安装最新的 LTS 版本 Node.js
    echo "正在安装最新的 LTS 版本 Node.js..."
    nvm install --lts || error_exit "无法安装 LTS 版本的 Node.js"
    nvm use --lts || error_exit "无法切换到 LTS 版本的 Node.js"
    
    success "Node.js LTS 版本已安装并激活"
    echo -e "Node.js 版本: $(node --version)"
    echo -e "npm 版本: $(npm --version)"
    
    echo -e "要在新的终端会话中使用 NVM，请运行以下命令或将其添加到您的 shell 配置文件中:"
    echo -e "${YELLOW}export NVM_DIR=\"\$HOME/.nvm\"
[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"  # 加载 NVM
[ -s \"\$NVM_DIR/bash_completion\" ] && \. \"\$NVM_DIR/bash_completion\"  # 加载 NVM bash_completion${NC}"
else
    error_exit "NVM 安装似乎失败，请检查错误消息并重试"
fi

success "NVM 和 Node.js LTS 版本安装完成!"