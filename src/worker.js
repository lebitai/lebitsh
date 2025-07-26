export default {
  /**
   * @param {Request} request
   * @param {{ ASSETS: { fetch: (request: Request) => Promise<Response> } }} env
   * @param {any} ctx
   * @returns {Promise<Response>}
   */
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    const userAgent = request.headers.get("User-Agent") || "";
    
    console.log("Path:", path);
    console.log("Full URL:", request.url);
    console.log("User-Agent:", userAgent);
    
    // 检查是否是 curl/wget 请求
    const isCommandLineRequest = userAgent.toLowerCase().includes("curl") || 
                                userAgent.toLowerCase().includes("wget");
    
    // 定义模块映射
    const modules = ['system', 'docker', 'dev', 'tools', 'mining'];
    const modulePath = path.slice(1).split('/')[0]; // 获取第一级路径
    
    // 定义通用的模块安装脚本生成函数
    const generateModuleScript = (module) => {
      return `#!/bin/bash

# Lebit.sh ${module.charAt(0).toUpperCase() + module.slice(1)} Module Installation Script

set -e

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Download and execute the main script with module parameter
echo "[INFO] Installing Lebit.sh ${module} module..."

if ! curl -fsSL "https://raw.githubusercontent.com/lebitai/lebitsh/main/main.sh" -o main.sh; then
    echo "[ERROR] Failed to download main installer" >&2
    rm -rf "$TEMP_DIR"
    exit 1
fi

chmod +x main.sh
bash main.sh ${module}

# Cleanup
rm -rf "$TEMP_DIR"
`;
    };
    
    // 定义主安装脚本内容
    const installScript = `#!/bin/bash

# Lebit.sh Installation Script

set -e

# Colors (using tput for better compatibility)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
NC=$(tput sgr0) # No Color

# Function to print colored output
info() {
    echo "[INFO] $1"
}

success() {
    echo "[SUCCESS] $1"
}

warning() {
    echo "[WARNING] $1"
}

error() {
    echo "[ERROR] $1" >&2
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        error "This script should not be run as root. Please run without sudo."
        exit 1
    fi
}

# Function to detect OS
detect_os() {
    if [[ "$(uname)" != "Linux" ]]; then
        error "This script is designed for Linux systems only"
        exit 1
    fi

    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        DISTRO=$(lsb_release -si)
        VERSION=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # shellcheck disable=SC1091
        source /etc/lsb-release
        DISTRO=$DISTRIB_ID
        VERSION=$DISTRIB_RELEASE
    else
        error "Unsupported Linux distribution"
        exit 1
    fi

    # Convert to lowercase
    DISTRO=$(echo "$DISTRO" | tr '[:upper:]' '[:lower:]')
    info "Detected OS: $DISTRO:$VERSION"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check internet connection
check_internet() {
    info "Checking internet connection..."
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        success "Internet connection is available"
    else
        error "No internet connection detected"
        exit 1
    fi
}

# Function to install required packages
install_packages() {
    info "Installing required packages..."
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt-get update -qq >/dev/null
            sudo apt-get install -y curl sudo >/dev/null 2>&1
            ;;
        centos|rhel|fedora|rocky|almalinux)
            if command_exists dnf; then
                sudo dnf install -y curl sudo >/dev/null 2>&1
            else
                sudo yum install -y curl sudo >/dev/null 2>&1
            fi
            ;;
        *)
            error "Unsupported distribution: $DISTRO"
            exit 1
            ;;
    esac
    
    success "Required packages installed"
}

# Function to download and run the main installer
install_lebitsh() {
    info "Downloading Lebit.sh..."
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Download the main script
    if ! curl -fsSL "https://raw.githubusercontent.com/lebitai/lebitsh/main/main.sh" -o main.sh; then
        error "Failed to download main installer"
        cleanup
        exit 1
    fi
    
    # Make it executable
    chmod +x main.sh
    
    success "Download completed"
    
    # Run the main installer
    info "Running Lebit.sh installer..."
    bash main.sh "$@"
    
    # Cleanup
    cleanup
}

# Function to cleanup temporary files
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Main function
main() {
    # Check if we're running as root
    check_root
    
    # Detect OS
    detect_os
    
    # Check internet connection
    check_internet
    
    # Install required packages
    install_packages
    
    # Install Lebit.sh
    install_lebitsh "$@"
    
    success "Lebit.sh installation completed!"
    echo "You can now run 'lebitsh' to start the toolkit."
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Run main function with all arguments
main "$@"
`;
    
    // 处理命令行请求
    if (isCommandLineRequest) {
      // 如果请求的是模块路径（如 /system, /docker 等）
      if (modules.includes(modulePath)) {
        console.log(`Serving ${modulePath} module script for command line tool`);
        
        return new Response(generateModuleScript(modulePath), {
          headers: {
            "Content-Type": "text/plain; charset=utf-8",
            "Cache-Control": "no-cache, no-store, must-revalidate"
          }
        });
      }
      
      // 如果请求的是根路径或 /install 路径
      if (path === "/" || path === "/install" || path === "/install/") {
        console.log("Serving install script for command line tool");
        
        return new Response(installScript, {
          headers: {
            "Content-Type": "text/plain; charset=utf-8",
            "Cache-Control": "no-cache, no-store, must-revalidate"
          }
        });
      }
    }
    
    // 处理浏览器请求
    if (!isCommandLineRequest) {
      // 如果浏览器访问模块路径，返回404或重定向到模块文档
      if (modules.includes(modulePath)) {
        // 重定向到模块文档页面
        return Response.redirect(`${url.origin}/modules.html#${modulePath}`, 302);
      }
      
      // 如果浏览器访问 /install 路径，返回安装脚本作为下载
      if (path === "/install" || path === "/install/") {
        console.log("Serving install script for browser");
        
        return new Response(installScript, {
          headers: {
            "Content-Type": "text/plain; charset=utf-8",
            "Content-Disposition": 'attachment; filename="install.sh"',
            "Cache-Control": "no-cache, no-store, must-revalidate"
          }
        });
      }
    }
    
    // 对于所有其他路径，提供静态资产（网站内容）
    console.log("Serving static assets for path:", path);
    return env.ASSETS.fetch(request);
  }
};