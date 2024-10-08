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

# Function: Uninstall existing Golang
uninstall_existing_golang() {
    if command -v go &> /dev/null; then
        echo -e "${YELLOW}Detected existing Golang installation, uninstalling...${NC}"
        if sudo -v &> /dev/null; then
            sudo rm -rf /usr/local/go
            sudo rm -f /etc/profile.d/golang.sh
            echo -e "${YELLOW}Uninstalled old version of Golang${NC}"
        else
            error_exit "Current user doesn't have sudo privileges, cannot uninstall existing Golang"
        fi
    fi
}

# Function: Install Golang
install_golang() {
    # Get the latest stable version of Golang
    echo -e "${GREEN}Fetching the latest Golang version...${NC}"
    if ! command -v curl &> /dev/null; then
        error_exit "curl command not found, cannot fetch latest Golang version"
    fi
    if ! command -v grep &> /dev/null; then
        error_exit "grep command not found, cannot fetch latest Golang version"
    fi
    GO_VERSION=$(curl -sSL https://go.dev/VERSION?m=text | grep -o 'go[0-9.]*')
    [ -z "$GO_VERSION" ] && error_exit "Unable to fetch latest Golang version"
    echo -e "${GREEN}Detected latest Golang version: $GO_VERSION${NC}"

    # Determine OS and architecture
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv*) ARCH="armv6l" ;;
        *) error_exit "Unsupported architecture: $ARCH" ;;
    esac

    # Download URL
    DOWNLOAD_URL="https://golang.org/dl/${GO_VERSION}.${OS}-${ARCH}.tar.gz"
    echo "Golang URL is : ${DOWNLOAD_URL}"

    # Detect package manager
    echo -e "${GREEN}Detecting package manager...${NC}"
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt-get"
        echo -e "${GREEN}Installing necessary tools: curl, tar...${NC}"
        sudo apt-get update && sudo apt-get install -y curl tar
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        echo -e "${GREEN}Installing necessary tools: curl, tar...${NC}"
        sudo yum install -y curl tar
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        echo -e "${GREEN}Installing necessary tools: curl, tar...${NC}"
        sudo dnf install -y curl tar
    else
        error_exit "Unknown package manager, cannot continue installation"
    fi

    # Download Golang
    echo -e "${GREEN}Downloading Golang...${NC}"
    curl -LO "$DOWNLOAD_URL" || error_exit "Failed to download Golang"

    # Extract and install Golang
    echo -e "${GREEN}Installing Golang...${NC}"
    if sudo -v &> /dev/null; then
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "${GO_VERSION}.${OS}-${ARCH}.tar.gz" || error_exit "Failed to extract Golang"
        rm "${GO_VERSION}.${OS}-${ARCH}.tar.gz"
    else
        error_exit "Current user doesn't have sudo privileges, cannot install Golang"
    fi

    # Set environment variables
    echo -e "${GREEN}Setting environment variables...${NC}"
    if [ -w ~/.bashrc ]; then
        if ! grep -q "export PATH=\$PATH:/usr/local/go/bin" ~/.bashrc; then
            echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
        fi
        export PATH=$PATH:/usr/local/go/bin
    else
        error_exit "Current user doesn't have write permission for ~/.bashrc, cannot set environment variables"
    fi

    # Verify installation
    echo -e "${GREEN}Verifying Golang installation...${NC}"
    if /usr/local/go/bin/go version &> /dev/null; then
        GO_INSTALLED_VERSION=$(/usr/local/go/bin/go version | awk '{print $3}')
        echo -e "${GREEN}Golang installed successfully, version: $GO_INSTALLED_VERSION${NC}"
    else
        error_exit "Golang installation failed or environment variables are not set correctly"
    fi

    echo -e "${GREEN}Golang installation complete${NC}"
    echo -e "${YELLOW}Please run 'source ~/.bashrc' or log out and log back in to ensure environment variables are effective in all shell sessions${NC}"
}

# Main function
main() {
    show_brand

    # Ask user whether to continue installation
    read -p "Do you want to install/update Golang on this machine? (yes/no): " answer
    if ! echo "$answer" | grep -iq "^y"; then
        echo -e "${YELLOW}User cancelled installation, exiting script.${NC}"
        exit 0
    fi

    # Start installation
    echo -e "${GREEN}Starting Golang installation...${NC}"

    # Uninstall existing Golang
    uninstall_existing_golang

    # Install Golang
    install_golang
}

# Call main function
main
