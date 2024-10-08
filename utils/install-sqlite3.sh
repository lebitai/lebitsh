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

# Function: Output error message and exit
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Function: Output success message
success_msg() {
    echo -e "${GREEN}$1${NC}"
}

# Function: Check if SQLite3 is already installed
check_sqlite3() {
    if command -v sqlite3 &> /dev/null; then
        echo -e "${GREEN}SQLite3 is already installed.${NC}"
        sqlite3 --version
        return 0
    else
        echo -e "${YELLOW}SQLite3 is not installed.${NC}"
        return 1
    fi
}

# Function: Install SQLite3
install_sqlite3() {
    # Check if running with root privileges
    if [ "$EUID" -ne 0 ]; then
        error_exit "Please run this script with root privileges"
    fi

    # Detect operating system
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
    else
        error_exit "Unable to detect operating system"
    fi

    # Install SQLite3 based on the operating system
    case $OS in
        "Ubuntu"|"Debian GNU/Linux")
            echo "Updating package list..."
            apt update || error_exit "Unable to update package list"

            echo "Installing SQLite3..."
            apt install -y sqlite3 || error_exit "Unable to install SQLite3"
            ;;
        "CentOS Linux"|"Red Hat Enterprise Linux")
            echo "Installing SQLite3..."
            yum install -y sqlite || error_exit "Unable to install SQLite3"
            ;;
        *)
            error_exit "Unsupported operating system: $OS"
            ;;
    esac

    # Verify installation
    if command -v sqlite3 &> /dev/null; then
        VERSION=$(sqlite3 --version)
        success_msg "SQLite3 installed successfully! Version: $VERSION"
    else
        error_exit "SQLite3 installation failed"
    fi
}

# Function: Display usage information
show_usage() {
    echo "
SQLite3 Basic Usage:
1. Create/open a database: sqlite3 database.db
2. At the SQLite prompt, you can enter SQL commands
3. Exit SQLite: .quit

For more information, please refer to the SQLite documentation."
}

# Main function
main() {
    show_brand

    echo -e "${YELLOW}Checking existing SQLite3 installation...${NC}"
    if check_sqlite3; then
        echo -e "${GREEN}SQLite3 is already installed. Skipping installation.${NC}"
    else
        install_sqlite3
    fi

    show_usage
    success_msg "Installation script completed"
}

# Call main function
main
