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

# Download the complete Lebit.sh package
echo "[INFO] Downloading Lebit.sh..."

if ! curl -fsSL "https://github.com/lebitai/lebitsh/archive/refs/heads/main.tar.gz" -o lebitsh.tar.gz; then
    echo "[ERROR] Failed to download Lebit.sh package" >&2
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Extract the tarball
if ! tar -xzf lebitsh.tar.gz; then
    echo "[ERROR] Failed to extract Lebit.sh package" >&2
    rm -rf "$TEMP_DIR"
    exit 1
fi

cd lebitsh-main
chmod +x main.sh
find . -name "*.sh" -type f -exec chmod +x {} \\; 2>/dev/null || true

# Install and run specific module
echo "[INFO] Installing ${module} module..."
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
if command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1 2>/dev/null || echo "")
    GREEN=$(tput setaf 2 2>/dev/null || echo "")
    YELLOW=$(tput setaf 3 2>/dev/null || echo "")
    BLUE=$(tput setaf 4 2>/dev/null || echo "")
    NC=$(tput sgr0 2>/dev/null || echo "")
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    NC=""
fi

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
    if [ "$(id -u)" -eq 0 ]; then
        warning "Running as root user. Some operations may have different behavior."
        warning "For better security, consider creating a regular user account."
    fi
}

# Function to detect OS
detect_os() {
    if [ "$(uname)" != "Linux" ]; then
        error "This script is designed for Linux systems only"
        exit 1
    fi

    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    elif command -v lsb_release >/dev/null 2>&1; then
        DISTRO=$(lsb_release -si)
        VERSION=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # shellcheck disable=SC1091
        . /etc/lsb-release
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
    
    # Download the entire repository as a tarball
    info "Downloading complete Lebit.sh package..."
    if ! curl -fsSL "https://github.com/lebitai/lebitsh/archive/refs/heads/main.tar.gz" -o lebitsh.tar.gz; then
        error "Failed to download Lebit.sh package"
        cleanup
        exit 1
    fi
    
    # Extract the tarball
    if ! tar -xzf lebitsh.tar.gz; then
        error "Failed to extract Lebit.sh package"
        cleanup
        exit 1
    fi
    
    # Move to the extracted directory
    cd lebitsh-main
    
    # Make scripts executable
    chmod +x main.sh
    find . -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true
    
    success "Download completed"
    
    # Run the main installer
    info "Running Lebit.sh installer..."
    
    # Check if we're in a pipe/non-interactive mode
    if [ -t 0 ] && [ -t 1 ]; then
        # Interactive mode - run main.sh directly
        bash main.sh "$@"
    else
        # Non-interactive mode - just download and install
        info "Detected non-interactive installation"
        
        # If specific module requested, show instructions
        if [ $# -gt 0 ]; then
            MODULE="$1"
            info "To install $MODULE module, run this after installation:"
            echo "  bash $TEMP_DIR/main.sh $MODULE"
        fi
        
        # Create installation directory
        INSTALL_DIR="/opt/lebitsh"
        if [ "$(id -u)" -eq 0 ]; then
            # Running as root
            mkdir -p "$INSTALL_DIR"
            TARGET_DIR="$INSTALL_DIR"
            BIN_DIR="/usr/local/bin"
        else
            # Running as regular user
            INSTALL_DIR="$HOME/.lebitsh"
            mkdir -p "$INSTALL_DIR"
            TARGET_DIR="$INSTALL_DIR"
            BIN_DIR="$HOME/.local/bin"
            mkdir -p "$BIN_DIR"
        fi
        
        # Copy all files to installation directory
        info "Installing Lebit.sh to $TARGET_DIR..."
        cp -r . "$TARGET_DIR/"
        
        # Verify installation
        if [ ! -f "$TARGET_DIR/main.sh" ]; then
            error "Installation failed: main.sh not found"
            cleanup
            exit 1
        fi
        
        # Verify modules
        for module in system docker dev tools mining; do
            if [ ! -f "$TARGET_DIR/modules/$module/main.sh" ]; then
                warning "Module $module not found, some features may not work"
            fi
        done
        
        # Create launcher script
        cat > "$BIN_DIR/lebitsh" << EOF
#!/bin/bash
cd "$TARGET_DIR" && bash main.sh "\$@"
EOF
        chmod +x "$BIN_DIR/lebitsh"
        
        success "Installation completed!"
        echo ""
        info "Lebit.sh has been installed successfully!"
        info "Location: $TARGET_DIR"
        echo ""
        info "To use Lebit.sh, run:"
        echo "  lebitsh"
        echo ""
        
        if [ "$(id -u)" -ne 0 ] && ! echo "$PATH" | grep -q "$BIN_DIR"; then
            warning "Please add $BIN_DIR to your PATH or restart your shell"
        fi
        
        # If module was specified, provide direct command
        if [ $# -gt 0 ]; then
            echo ""
            info "To install $MODULE module directly, run:"
            echo "  lebitsh $MODULE"
        fi
    fi
    
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