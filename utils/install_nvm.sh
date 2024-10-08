#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function: Display brand
show_brand() {
    clear
    echo -e "${WHITE}"
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
    echo -e "${NC}"
}

# Error handling function
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Warning function
warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

# Success message function
success() {
    echo -e "${GREEN}$1${NC}"
}

# Function to check if NVM is already installed
check_nvm() {
    if [ -d "$HOME/.nvm" ]; then
        echo -e "${GREEN}NVM is already installed.${NC}"
        return 0
    else
        echo -e "${YELLOW}NVM is not installed.${NC}"
        return 1
    fi
}

# Function to install NVM
install_nvm() {
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        warning "curl is not installed. Attempting to install..."
        if [ -f /etc/debian_version ]; then
            sudo apt update && sudo apt install -y curl || error_exit "Unable to install curl"
        elif [ -f /etc/redhat-release ]; then
            sudo yum install -y curl || error_exit "Unable to install curl"
        else
            error_exit "Unsupported operating system. Please install curl manually."
        fi
    fi

    # Get the latest NVM version
    echo "Fetching the latest NVM version..."
    NVM_LATEST=$(curl -sL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    [ -z "$NVM_LATEST" ] && error_exit "Unable to fetch the latest NVM version"
    success "Detected latest NVM version: $NVM_LATEST"

    # Download and run NVM installation script
    echo "Downloading and installing NVM..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_LATEST/install.sh" | bash || error_exit "NVM installation failed"

    # Set up NVM environment variables
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # Load NVM
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # Load NVM bash_completion

    # Verify installation
    if command -v nvm &> /dev/null; then
        success "NVM has been successfully installed!"
        echo -e "NVM version: $(nvm --version)"
        
        # Install the latest LTS version of Node.js
        echo "Installing the latest LTS version of Node.js..."
        nvm install --lts || error_exit "Unable to install LTS version of Node.js"
        nvm use --lts || error_exit "Unable to switch to LTS version of Node.js"
        
        success "Node.js LTS version has been installed and activated"
        echo -e "Node.js version: $(node --version)"
        echo -e "npm version: $(npm --version)"
        
        echo -e "To use NVM in new terminal sessions, run the following commands or add them to your shell configuration file:"
        echo -e "${YELLOW}export NVM_DIR=\"\$HOME/.nvm\"
[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"  # Load NVM
[ -s \"\$NVM_DIR/bash_completion\" ] && \. \"\$NVM_DIR/bash_completion\"  # Load NVM bash_completion${NC}"
    else
        error_exit "NVM installation seems to have failed. Please check error messages and try again."
    fi

    success "NVM and Node.js LTS version installation complete!"
}

# Main function
main() {
    show_brand

    echo -e "${YELLOW}Checking existing NVM installation...${NC}"
    if check_nvm; then
        echo -e "${GREEN}NVM is already installed. Skipping installation.${NC}"
        # You might want to add an update option here if needed
    else
        install_nvm
    fi
}

# Call main function
main
