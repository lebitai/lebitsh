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
    
    # Download the main script
    if ! download_with_cache "$url" "$cache_file"; then
        echo "[ERROR] Failed to load $script_path" >&2
        return 1
    fi
    
    # Create a temporary directory for execution
    EXEC_DIR=$(mktemp -d)
    local original_dir=$(pwd)
    
    # Set up directory structure
    mkdir -p "$EXEC_DIR/common"
    mkdir -p "$EXEC_DIR/modules"
    
    # Download common dependencies
    echo "[INFO] Downloading dependencies..."
    for dep in ui.sh logging.sh config.sh utils.sh; do
        if ! download_with_cache "$GITHUB_BASE/common/$dep" "$EXEC_DIR/common/$dep"; then
            echo "[WARNING] Failed to download common/$dep - some features may not work"
        fi
    done
    
    # Copy the script to the correct location in execution directory
    local target_path="$EXEC_DIR/$script_path"
    mkdir -p "$(dirname "$target_path")"
    cp "$cache_file" "$target_path"
    chmod +x "$target_path"
    
    # For main.sh, download all module main.sh files since they might be called
    if [[ "$script_path" == "main.sh" ]]; then
        echo "[INFO] Preparing modules..."
        for module in system docker dev tools mining; do
            local module_main="modules/$module/main.sh"
            mkdir -p "$EXEC_DIR/modules/$module"
            if download_with_cache "$GITHUB_BASE/$module_main" "$EXEC_DIR/$module_main"; then
                chmod +x "$EXEC_DIR/$module_main"
            else
                echo "[WARNING] Failed to download $module_main"
            fi
        done
    fi
    
    # For module scripts, also download their dependencies
    if [[ "$script_path" == modules/*/main.sh ]]; then
        local module_dir=$(dirname "$script_path")
        echo "[INFO] Downloading module dependencies..."
        
        # Download module-specific files based on module type
        case "$module_dir" in
            "modules/system")
                for file in cleanup.sh hwinfo.sh sync_time.sh; do
                    if download_with_cache "$GITHUB_BASE/$module_dir/$file" "$EXEC_DIR/$module_dir/$file" 2>/dev/null; then
                        chmod +x "$EXEC_DIR/$module_dir/$file" 2>/dev/null || true
                    fi
                done
                ;;
            "modules/docker")
                for file in install.sh monitor.sh upgrade.sh; do
                    if download_with_cache "$GITHUB_BASE/$module_dir/$file" "$EXEC_DIR/$module_dir/$file" 2>/dev/null; then
                        chmod +x "$EXEC_DIR/$module_dir/$file" 2>/dev/null || true
                    fi
                done
                ;;
            "modules/dev")
                for file in golang.sh node.sh rust.sh sqlite.sh quickalias.sh; do
                    if download_with_cache "$GITHUB_BASE/$module_dir/$file" "$EXEC_DIR/$module_dir/$file" 2>/dev/null; then
                        chmod +x "$EXEC_DIR/$module_dir/$file" 2>/dev/null || true
                    fi
                done
                ;;
            "modules/tools")
                for file in alias_manager.sh renew_ssl.sh; do
                    if download_with_cache "$GITHUB_BASE/$module_dir/$file" "$EXEC_DIR/$module_dir/$file" 2>/dev/null; then
                        chmod +x "$EXEC_DIR/$module_dir/$file" 2>/dev/null || true
                    fi
                done
                ;;
        esac
        
        # For mining modules, check for subdirectories
        if [[ "$module_dir" == "modules/mining" ]]; then
            for submodule in Ritual TitanNetwork EthStorage; do
                if download_with_cache "$GITHUB_BASE/$module_dir/$submodule/install.sh" "$EXEC_DIR/$module_dir/$submodule/install.sh" 2>/dev/null; then
                    chmod +x "$EXEC_DIR/$module_dir/$submodule/install.sh" 2>/dev/null || true
                fi
            done
        fi
    fi
    
    # Change to execution directory and run the script
    cd "$EXEC_DIR"
    
    # Set environment variables that scripts expect
    export SCRIPT_DIR="$EXEC_DIR"
    export COMMON_DIR="$EXEC_DIR/common"
    export MODULES_DIR="$EXEC_DIR/modules"
    
    # Run the script from its expected location
    bash "$script_path" $args
    local exit_code=$?
    
    # Cleanup
    cd "$original_dir"
    rm -rf "$EXEC_DIR"
    
    return $exit_code
}

# Show banner
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