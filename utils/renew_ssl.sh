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

# Function: Check if certbot is installed
check_certbot() {
    if command -v certbot &> /dev/null; then
        echo -e "${GREEN}Certbot is already installed.${NC}"
        return 0
    else
        echo -e "${YELLOW}Certbot is not installed.${NC}"
        return 1
    fi
}

# Function: Install certbot
install_certbot() {
    echo "Installing Certbot..."
    if [ -f /etc/debian_version ]; then
        sudo apt-get update
        sudo apt-get install -y certbot || error_exit "Failed to install Certbot"
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y certbot || error_exit "Failed to install Certbot"
    else
        error_exit "Unsupported operating system. Please install Certbot manually."
    fi
    success_msg "Certbot installed successfully."
}

# Function: Renew SSL certificate
renew_ssl_by_domain() {
    # Check if certbot is installed
    if ! check_certbot; then
        install_certbot
    fi

    # Update the system packages
    echo "Updating system packages..."
    if [ -f /etc/debian_version ]; then
        sudo apt-get update || error_exit "Failed to update system packages"
    elif [ -f /etc/redhat-release ]; then
        sudo yum update -y || error_exit "Failed to update system packages"
    fi

    # Prompt user to enter the domain name
    while true; do
        read -p "Enter the domain name to renew the SSL certificate: " renew_domain
        if [[ -n "$renew_domain" ]]; then
            break
        else
            echo -e "${YELLOW}Domain name cannot be empty. Please try again.${NC}"
        fi
    done

    # Prompt user to enter the path to the certificate
    while true; do
        read -p "Enter the full path of the certificate directory: " cert_path
        if [[ -d "$cert_path" ]]; then
            break
        else
            echo -e "${YELLOW}Invalid directory path. Please try again.${NC}"
        fi
    done

    # Renew SSL certificate for domains using Certbot
    echo "Renewing SSL certificate..."
    if sudo certbot renew -d "$renew_domain" --config-dir "$cert_path" --quiet; then
        success_msg "SSL certificate for $renew_domain has been successfully renewed."
    else
        error_exit "Failed to renew SSL certificate for $renew_domain"
    fi
}

# Function: Display menu and get user input
display_menu() {
    echo -e "${YELLOW}Please select the operation to be performed:${NC}"
    echo "1. Renew SSL certificate"
    echo "2. Exit"
    
    while true; do
        read -p "Please enter an option (1-2): " option
        case $option in
            1) renew_ssl_by_domain; break ;;
            2) echo "Exiting..."; exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
        esac
    done
}

# Main function
main() {
    show_brand
    echo "Welcome to the SSL Certificate Renewal Service."
    echo "================================================"
    display_menu
}

# Call main function
main
