#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
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

# Function: Output colored log
log() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date +'%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

# Function: Output error log and exit
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Function: Uninstall existing Rust
uninstall_existing_rust() {
    if command -v rustc &> /dev/null; then
        echo -e "${YELLOW}Detected existing Rust installation, uninstalling...${NC}"
        rustup self uninstall -y
        echo -e "${YELLOW}Uninstalled old version of Rust${NC}"
    fi
}

# Function: Install Rust
install_rust() {
    # Check necessary tools
    echo -e "${GREEN}Checking necessary tools...${NC}"
    if ! command -v curl &> /dev/null; then
        error_exit "curl command not found, please install curl first"
    fi

    # Download and run Rust installation script
    echo -e "${GREEN}Downloading and running Rust installation script...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    # Set environment variables
    echo -e "${GREEN}Setting environment variables...${NC}"
    if [ -w ~/.bashrc ]; then
        if ! grep -q "source \$HOME/.cargo/env" ~/.bashrc; then
            echo "source \$HOME/.cargo/env" >> ~/.bashrc
        fi
        source $HOME/.cargo/env
    else
        error_exit "Current user doesn't have write permission for ~/.bashrc, cannot set environment variables"
    fi

    # Verify installation
    echo -e "${GREEN}Verifying Rust installation...${NC}"
    if rustc --version &> /dev/null; then
        RUST_VERSION=$(rustc --version | awk '{print $2}')
        echo -e "${GREEN}Rust installed successfully, version: $RUST_VERSION${NC}"
    else
        error_exit "Rust installation failed or environment variables are not set correctly"
    fi

    echo -e "${GREEN}Rust installation complete${NC}"
    echo -e "${YELLOW}Please run 'source ~/.bashrc' or log out and log back in to ensure environment variables are effective in all shell sessions${NC}"
}

# Main function
main() {
    show_brand

    # Ask user whether to continue installation
    read -p "Do you want to install/update Rust on this machine? (yes/no): " answer
    if ! echo "$answer" | grep -iq "^y"; then
        echo -e "${YELLOW}User cancelled installation, exiting script.${NC}"
        exit 0
    fi

    # Start installation
    echo -e "${GREEN}Starting Rust installation...${NC}"

    # Uninstall existing Rust
    uninstall_existing_rust

    # Install Rust
    install_rust
}

# Call main function
main
