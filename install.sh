#!/bin/bash

# Function to display usage instructions
show_usage() {
    cat << EOF
Usage: curl --proto '=https' --tlsv1.2 -sSf https://lebit.sh | sh [-s -- [module]]

Available modules:
  docker    - Docker management tools
  dev       - Development environment setup
  system    - System optimization and management
  tools     - Utility tools and scripts
  mining    - Cryptocurrency mining tools

If no module is specified, the script will provide an interactive menu.

Examples:
  curl --proto '=https' --tlsv1.2 -sSf https://docker.lebit.sh | sh
  curl --proto '=https' --tlsv1.2 -sSf https://lebit.sh | sh -s -- docker
EOF
    exit 0
}

# Function to download and execute a module
download_and_execute() {
    local module="$1"
    local temp_dir
    temp_dir=$(mktemp -d)
    
    echo "Downloading $module module..."
    
    # This simulates downloading the module; in production this would fetch from the actual server
    if [ -d "/Users/xiaoli/devops/lebitai/lebitsh/modules/$module" ]; then
        mkdir -p "$temp_dir/common"
        cp -r "/Users/xiaoli/devops/lebitai/lebitsh/common"/* "$temp_dir/common/"
        mkdir -p "$temp_dir/modules/$module"
        cp -r "/Users/xiaoli/devops/lebitai/lebitsh/modules/$module"/* "$temp_dir/modules/$module/"
        
        # Execute the main script for the module
        if [ -f "$temp_dir/modules/$module/main.sh" ]; then
            chmod +x "$temp_dir/modules/$module/main.sh"
            bash "$temp_dir/modules/$module/main.sh"
        else
            echo "Error: Module main script not found"
            rm -rf "$temp_dir"
            exit 1
        fi
    else
        echo "Error: Module '$module' not found"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Function to display the main menu
show_main_menu() {
    echo "
.-------------------------------------.
| _         _     _ _     ____  _   _ |
|| |    ___| |__ (_) |_  / ___|| | | ||
|| |   / _ \ '_ \| | __| \___ \| |_| ||
|| |__|  __/ |_) | | |_ _ ___) |  _  ||
||_____\___|_.__/|_|\__(_)____/|_| |_||
'-------------------------------------'      
            https://lebit.sh
"
    echo "Welcome to Lebit.sh - Your Linux system initialization toolkit"
    echo "================================================================"
    echo "Please select a module to use:"
    echo "1. System Management"
    echo "2. Docker Management"
    echo "3. Development Environment"
    echo "4. System Tools"
    echo "5. Mining Tools"
    echo "6. Exit"
    
    read -p "Please enter an option (1-6): " OPTION
    
    case $OPTION in
        1)
            download_and_execute "system"
            ;;
        2)
            download_and_execute "docker"
            ;;
        3)
            download_and_execute "dev"
            ;;
        4)
            download_and_execute "tools"
            ;;
        5)
            download_and_execute "mining"
            ;;
        6)
            exit 0
            ;;
        *)
            echo "Invalid option, please try again."
            show_main_menu
            ;;
    esac
}

# Main script execution

# Check if a module was specified as an argument
if [ "$#" -ge 2 ] && [ "$1" = "--" ]; then
    MODULE="$2"
    
    case $MODULE in
        "help")
            show_usage
            ;;
        "docker"|"dev"|"system"|"tools"|"mining")
            download_and_execute "$MODULE"
            ;;
        *)
            echo "Error: Unknown module '$MODULE'"
            show_usage
            ;;
    esac
else
    # No valid module specified, show interactive menu
    show_main_menu
fi
