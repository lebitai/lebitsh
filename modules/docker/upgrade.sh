#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"

# Function: Upgrade Docker
upgrade_docker() {
    show_brand
    section_header "Docker Upgrade"
    
    # Check if root
    check_root
    
    # Check if Docker is installed
    if ! command_exists docker; then
        error_msg "Docker is not installed"
        info_msg "Please install Docker first with:"
        echo "  curl --proto '=https' --tlsv1.2 -sSf https://lebit.sh/docker | sh"
        exit 1
    fi
    
    # Get current Docker version
    current_version=$(docker --version | cut -d ' ' -f3 | tr -d ',')
    info_msg "Current Docker version: $current_version"
    
    # Check internet connection
    if ! check_internet; then
        exit 1
    fi
    
    # Detect OS
    os_info=$(check_os)
    distro=$(echo "$os_info" | cut -d':' -f1)
    
    # Upgrade Docker based on distribution
    case $distro in
        ubuntu|debian)
            show_progress "Updating package lists"
            apt-get update -qq >/dev/null
            complete_progress_success
            
            show_progress "Upgrading Docker"
            apt-get install --only-upgrade -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null 2>&1
            complete_progress_success
            ;;
            
        centos|rhel|fedora|rocky|almalinux)
            show_progress "Upgrading Docker"
            if command_exists dnf; then
                dnf update -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null 2>&1
            else
                yum update -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null 2>&1
            fi
            complete_progress_success
            ;;
            
        *)
            error_msg "Unsupported distribution: $distro"
            exit 1
            ;;
    esac
    
    # Restart Docker service
    show_progress "Restarting Docker service"
    systemctl restart docker
    complete_progress_success
    
    # Get new Docker version
    new_version=$(docker --version | cut -d ' ' -f3 | tr -d ',')
    
    if [ "$current_version" != "$new_version" ]; then
        success_msg "Docker upgraded from $current_version to $new_version"
    else
        info_msg "Docker is already at the latest version ($current_version)"
    fi
    
    # Check Docker Compose version
    if command_exists docker-compose; then
        compose_version=$(docker-compose --version | cut -d ' ' -f3 | tr -d ',')
        info_msg "Docker Compose version: $compose_version"
    elif command_exists docker && docker compose version >/dev/null 2>&1; then
        compose_version=$(docker compose version --short)
        info_msg "Docker Compose Plugin version: $compose_version"
    fi
}

# Run the main function
upgrade_docker
