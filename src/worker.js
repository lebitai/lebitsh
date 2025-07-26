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

# Lebit.sh ${module.charAt(0).toUpperCase() + module.slice(1)} Module Quick Installer

set -e

echo "[INFO] Installing Lebit.sh and running ${module} module..."

# Download and execute the main installer with module parameter
if curl -fsSL https://lebit.sh/install | sh; then
    echo "[INFO] Running ${module} module..."
    # Try to run the module directly if lebitsh is in PATH
    if command -v lebitsh >/dev/null 2>&1; then
        lebitsh ${module}
    else
        # Fall back to direct execution
        if [ -f "/usr/local/bin/lebitsh" ]; then
            /usr/local/bin/lebitsh ${module}
        elif [ -f "$HOME/.local/bin/lebitsh" ]; then
            $HOME/.local/bin/lebitsh ${module}
        else
            echo "[ERROR] lebitsh command not found. Please run 'lebitsh ${module}' manually."
            exit 1
        fi
    fi
else
    echo "[ERROR] Failed to install Lebit.sh"
    exit 1
fi
`;
    };
    
    // 定义主安装脚本内容
    const installScript = `#!/bin/bash

# Lebit.sh Lightweight Installer & Launcher

set -e

# Configuration
GITHUB_BASE="https://raw.githubusercontent.com/lebitai/lebitsh/main"
CACHE_DIR="\${HOME}/.cache/lebitsh"
CACHE_EXPIRE=86400  # 24 hours in seconds

# Colors (using tput for better compatibility)
if command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1 2>/dev/null || echo "")
    GREEN=$(tput setaf 2 2>/dev/null || echo "")
    YELLOW=$(tput setaf 3 2>/dev/null || echo "")
    BLUE=$(tput setaf 4 2>/dev/null || echo "")
    WHITE=$(tput setaf 7 2>/dev/null || echo "")
    BOLD=$(tput bold 2>/dev/null || echo "")
    NC=$(tput sgr0 2>/dev/null || echo "")
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    WHITE=""
    BOLD=""
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

# Function to download file with caching
download_with_cache() {
    local url="$1"
    local cache_path="$2"
    local force_download="${3:-false}"
    
    # Create cache directory if it doesn't exist
    mkdir -p "$(dirname "$cache_path")"
    
    # Check if cached file exists and is not expired
    if [ "$force_download" = "false" ] && [ -f "$cache_path" ]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$cache_path" 2>/dev/null || stat -f %m "$cache_path" 2>/dev/null || echo 0)))
        if [ $file_age -lt $CACHE_EXPIRE ]; then
            return 0
        fi
    fi
    
    # Download file
    if curl -fsSL "$url" -o "$cache_path.tmp"; then
        mv "$cache_path.tmp" "$cache_path"
        chmod +x "$cache_path" 2>/dev/null || true
        return 0
    else
        rm -f "$cache_path.tmp"
        return 1
    fi
}

# Function to run remote script
run_remote_script() {
    local script_path="$1"
    shift
    local args="$@"
    
    local cache_file="$CACHE_DIR/$(echo "$script_path" | tr '/' '_')"
    local url="$GITHUB_BASE/$script_path"
    
    info "Loading $script_path..."
    
    if download_with_cache "$url" "$cache_file"; then
        bash "$cache_file" $args
    else
        error "Failed to load $script_path"
        return 1
    fi
}

# Function to show ASCII art banner
show_banner() {
    echo -e "${WHITE}"
    echo "***************************************"
    echo "* _         _     _ _     ____  _   _ *"
    echo "*| |    ___| |__ (_) |_  / ___|| | | |*"
    echo "*| |   / _ \\ '_ \\| | __| \\___ \\| |_| |*"
    echo "*| |__|  __/ |_) | | |_ _ ___) |  _  |*"
    echo "*|_____\\___|_.__/|_|\\__(_)____/|_| |_|*"
    echo "***************************************"
    echo "            https://lebit.sh"
    echo -e "${NC}"
}

# Function to show interactive menu
show_menu() {
    local PS3="Please select an option (1-8): "
    local options=(
        "System Management"
        "Docker Management"
        "Development Environment"
        "System Tools"
        "Mining Tools"
        "Update Cache"
        "Clear Cache"
        "Exit"
    )
    
    select opt in "${options[@]}"; do
        case $REPLY in
            1) run_module "system" ;;
            2) run_module "docker" ;;
            3) run_module "dev" ;;
            4) run_module "tools" ;;
            5) run_module "mining" ;;
            6) update_cache ;;
            7) clear_cache ;;
            8) exit 0 ;;
            *) echo "Invalid option" ;;
        esac
        break
    done
}

# Function to run specific module
run_module() {
    local module="$1"
    info "Loading $module module..."
    run_remote_script "modules/$module/main.sh"
}

# Function to update cache
update_cache() {
    info "Updating cache..."
    find "$CACHE_DIR" -type f -exec rm {} \\;
    success "Cache cleared. Next run will download fresh copies."
}

# Function to clear cache
clear_cache() {
    info "Clearing cache..."
    rm -rf "$CACHE_DIR"
    success "Cache cleared."
}

# Function to check if running as root
check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        warning "Running as root user."
    fi
}

# Main function for the launcher
main() {
    # Check if we have arguments
    if [ $# -gt 0 ]; then
        case "$1" in
            system|docker|dev|tools|mining)
                run_module "$1"
                ;;
            update)
                update_cache
                ;;
            clear-cache)
                clear_cache
                ;;
            *)
                error "Unknown command: $1"
                echo "Usage: lebitsh [system|docker|dev|tools|mining|update|clear-cache]"
                exit 1
                ;;
        esac
    else
        # Interactive mode
        clear
        show_banner
        while true; do
            show_menu
        done
    fi
}

# Installation function - creates a minimal launcher
install_lebitsh() {
    info "Installing Lebit.sh launcher..."
    
    
    # Determine installation location
    if [ "$(id -u)" -eq 0 ]; then
        BIN_DIR="/usr/local/bin"
    else
        BIN_DIR="$HOME/.local/bin"
        mkdir -p "$BIN_DIR"
    fi
    
    # Create the lebitsh launcher script
    cat > "$BIN_DIR/lebitsh" << 'LAUNCHER_SCRIPT'
#!/bin/bash

# Lebit.sh Lightweight Launcher
# This script downloads and executes Lebit.sh modules on demand

set -e

# Configuration
GITHUB_BASE="https://raw.githubusercontent.com/lebitai/lebitsh/main"
CACHE_DIR="${HOME}/.cache/lebitsh"
CACHE_EXPIRE=86400  # 24 hours in seconds

# Colors
if command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1 2>/dev/null || echo "")
    GREEN=$(tput setaf 2 2>/dev/null || echo "")
    YELLOW=$(tput setaf 3 2>/dev/null || echo "")
    BLUE=$(tput setaf 4 2>/dev/null || echo "")
    WHITE=$(tput setaf 7 2>/dev/null || echo "")
    BOLD=$(tput bold 2>/dev/null || echo "")
    NC=$(tput sgr0 2>/dev/null || echo "")
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; WHITE=""; BOLD=""; NC=""
fi

# Function to download file with caching
download_with_cache() {
    local url="$1"
    local cache_path="$2"
    local force="${3:-false}"
    
    mkdir -p "$(dirname "$cache_path")"
    
    if [ "$force" = "false" ] && [ -f "$cache_path" ]; then
        local file_age=$(($(date +%s) - $(stat -c %Y "$cache_path" 2>/dev/null || stat -f %m "$cache_path" 2>/dev/null || echo 0)))
        if [ $file_age -lt $CACHE_EXPIRE ]; then
            return 0
        fi
    fi
    
    if curl -fsSL "$url" -o "$cache_path.tmp"; then
        mv "$cache_path.tmp" "$cache_path"
        chmod +x "$cache_path" 2>/dev/null || true
        return 0
    else
        rm -f "$cache_path.tmp"
        return 1
    fi
}

# Function to run remote script with dependencies
run_remote_script() {
    local script_path="$1"
    shift
    local args="$@"
    
    local cache_file="$CACHE_DIR/$(echo "$script_path" | tr '/' '_')"
    local url="$GITHUB_BASE/$script_path"
    
    echo "[INFO] Loading $script_path..."
    
    if download_with_cache "$url" "$cache_file"; then
        # Create a temporary directory for execution
        EXEC_DIR=$(mktemp -d)
        cd "$EXEC_DIR"
        
        # Download common dependencies if needed
        if [[ "$script_path" == modules/* ]]; then
            mkdir -p common
            for dep in ui.sh logging.sh config.sh utils.sh; do
                download_with_cache "$GITHUB_BASE/common/$dep" "common/$dep" >/dev/null 2>&1 || true
            done
        fi
        
        # Set up environment
        export SCRIPT_DIR="$EXEC_DIR"
        export COMMON_DIR="$EXEC_DIR/common"
        export MODULES_DIR="$EXEC_DIR/modules"
        
        # Execute the script
        bash "$cache_file" $args
        local exit_code=$?
        
        # Cleanup
        cd - >/dev/null
        rm -rf "$EXEC_DIR"
        
        return $exit_code
    else
        echo "[ERROR] Failed to load $script_path" >&2
        return 1
    fi
}

# Show banner
show_banner() {
    echo -e "${WHITE}"
    echo "***************************************"
    echo "* _         _     _ _     ____  _   _ *"
    echo "*| |    ___| |__ (_) |_  / ___|| | | |*"
    echo "*| |   / _ \\\\ '_ \\\\| | __| \\\\___ \\\\| |_| |*"
    echo "*| |__|  __/ |_) | | |_ _ ___) |  _  |*"
    echo "*|_____\\\\___|_.__/|_|\\\\__(_)____/|_| |_|*"
    echo "***************************************"
    echo "            https://lebit.sh"
    echo -e "${NC}"
}

# Main logic
if [ $# -gt 0 ]; then
    case "$1" in
        system|docker|dev|tools|mining)
            run_remote_script "modules/$1/main.sh"
            ;;
        update-cache)
            echo "[INFO] Clearing cache for updates..."
            rm -rf "$CACHE_DIR"
            echo "[SUCCESS] Cache cleared"
            ;;
        version)
            echo "Lebit.sh Launcher v1.0"
            ;;
        help|--help|-h)
            show_banner
            echo "Usage: lebitsh [command]"
            echo ""
            echo "Commands:"
            echo "  system       - System management tools"
            echo "  docker       - Docker management tools"
            echo "  dev          - Development environment setup"
            echo "  tools        - System utilities"
            echo "  mining       - Mining tools"
            echo "  update-cache - Clear cache and fetch latest versions"
            echo "  version      - Show version"
            echo "  help         - Show this help"
            echo ""
            echo "Run without arguments for interactive menu"
            ;;
        *)
            echo "[ERROR] Unknown command: $1"
            echo "Run 'lebitsh help' for usage"
            exit 1
            ;;
    esac
else
    # Interactive mode - run the main menu from GitHub
    clear
    show_banner
    run_remote_script "main.sh"
fi
LAUNCHER_SCRIPT
    
    # Make the launcher executable
    chmod +x "$BIN_DIR/lebitsh"
    
    success "Installation completed!"
    echo ""
    info "Lebit.sh launcher has been installed!"
    echo ""
    info "Usage:"
    echo "  lebitsh              # Interactive menu"
    echo "  lebitsh system       # System management"
    echo "  lebitsh docker       # Docker management"
    echo "  lebitsh dev          # Development tools"
    echo "  lebitsh tools        # System utilities"
    echo "  lebitsh mining       # Mining tools"
    echo "  lebitsh help         # Show help"
    echo ""
    
    if [ "$(id -u)" -ne 0 ] && ! echo "$PATH" | grep -q "$BIN_DIR"; then
        warning "Add $BIN_DIR to your PATH:"
        echo "  echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> ~/.bashrc"
        echo "  source ~/.bashrc"
        echo ""
        info "Or run directly: $BIN_DIR/lebitsh"
    fi
}

# Main installation process
check_root
install_lebitsh "$@"
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