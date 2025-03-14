#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"

# Function: Install NVM and Node.js
install_node() {
    show_brand
    section_header "Node.js Installation (via NVM)"
    
    # Check internet connection
    if ! check_internet; then
        exit 1
    fi
    
    # Determine the user home directory
    if [ "$SUDO_USER" ]; then
        user_home=$(eval echo ~"$SUDO_USER")
        actual_user="$SUDO_USER"
    else
        user_home="$HOME"
        actual_user="$(whoami)"
    fi
    
    # Check if NVM is already installed
    if [ -d "$user_home/.nvm" ]; then
        info_msg "NVM is already installed"
        
        read -p "Do you want to update NVM? (y/n): " choice
        if [[ $choice =~ ^[Yy]$ ]]; then
            # Update NVM
            show_progress "Updating NVM"
            if [ "$SUDO_USER" ]; then
                su - "$SUDO_USER" -c "cd \"$user_home/.nvm\" && git pull" >/dev/null 2>&1
            else
                cd "$user_home/.nvm" && git pull >/dev/null 2>&1
            fi
            complete_progress_success
        else
            info_msg "Skipping NVM update"
        fi
    else
        # Install NVM
        info_msg "Installing NVM (Node Version Manager)"
        show_progress "Downloading and installing NVM"
        
        # Install prerequisites
        if [ "$(id -u)" -eq 0 ]; then
            install_packages git curl
        fi
        
        # Download and run install script
        if [ "$SUDO_USER" ]; then
            # Prevent running curl pipe to bash with sudo
            su - "$SUDO_USER" -c "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash" >/dev/null 2>&1
        else
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash >/dev/null 2>&1
        fi
        
        if [ -d "$user_home/.nvm" ]; then
            complete_progress_success
            success_msg "NVM installed successfully"
        else
            complete_progress_failure
            error_msg "Failed to install NVM"
            exit 1
        fi
    fi
    
    # Source NVM for the current shell
    export NVM_DIR="$user_home/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Check if Node.js is already installed via NVM
    if [ "$SUDO_USER" ]; then
        node_versions=$(su - "$SUDO_USER" -c "source \"$user_home/.nvm/nvm.sh\" && nvm ls" 2>/dev/null)
    else
        node_versions=$(nvm ls 2>/dev/null)
    fi
    
    if echo "$node_versions" | grep -q "node"; then
        info_msg "Node.js is already installed via NVM"
        
        # List installed versions
        if [ "$SUDO_USER" ]; then
            echo "Installed versions:"
            su - "$SUDO_USER" -c "source \"$user_home/.nvm/nvm.sh\" && nvm ls"
        else
            echo "Installed versions:"
            nvm ls
        fi
        
        read -p "Do you want to install another Node.js version? (y/n): " choice
        if [[ ! $choice =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    # Prompt for Node.js version
    echo ""
    info_msg "Available Node.js versions (LTS):"
    
    # Get latest LTS versions and display them
    if [ "$SUDO_USER" ]; then
        latest_lts=$(su - "$SUDO_USER" -c "source \"$user_home/.nvm/nvm.sh\" && nvm ls-remote --lts | tail -5")
    else
        latest_lts=$(nvm ls-remote --lts | tail -5)
    fi
    
    echo "$latest_lts"
    echo ""
    read -p "Enter Node.js version to install (e.g., 18.17.1, 'lts' for latest LTS): " node_version
    node_version=${node_version:-lts}
    
    # Install the specified Node.js version
    show_progress "Installing Node.js $node_version"
    if [ "$SUDO_USER" ]; then
        if [ "$node_version" = "lts" ]; then
            su - "$SUDO_USER" -c "source \"$user_home/.nvm/nvm.sh\" && nvm install --lts" >/dev/null 2>&1
        else
            su - "$SUDO_USER" -c "source \"$user_home/.nvm/nvm.sh\" && nvm install $node_version" >/dev/null 2>&1
        fi
    else
        if [ "$node_version" = "lts" ]; then
            nvm install --lts >/dev/null 2>&1
        else
            nvm install "$node_version" >/dev/null 2>&1
        fi
    fi
    
    # Verify installation
    if [ "$SUDO_USER" ]; then
        node_path=$(su - "$SUDO_USER" -c "source \"$user_home/.nvm/nvm.sh\" && which node")
        node_ver=$(su - "$SUDO_USER" -c "source \"$user_home/.nvm/nvm.sh\" && node --version")
        npm_ver=$(su - "$SUDO_USER" -c "source \"$user_home/.nvm/nvm.sh\" && npm --version")
    else
        node_path=$(which node)
        node_ver=$(node --version)
        npm_ver=$(npm --version)
    fi
    
    if [ -n "$node_path" ]; then
        complete_progress_success
        success_msg "Node.js $node_ver installed successfully"
        info_msg "npm version: $npm_ver"
        
        # Set as default if requested
        if [ "$SUDO_USER" ]; then
            su - "$SUDO_USER" -c "source \"$user_home/.nvm/nvm.sh\" && nvm alias default $node_ver" >/dev/null 2>&1
        else
            nvm alias default "$node_ver" >/dev/null 2>&1
        fi
        
        echo ""
        echo "To start using Node.js in this terminal, run:"
        echo "  export NVM_DIR=\"\$HOME/.nvm\""
        echo "  [ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\""
        echo ""
        echo "Or simply close and reopen your terminal."
    else
        complete_progress_failure
        error_msg "Failed to install Node.js"
        exit 1
    fi
}

# Run the main function
install_node
