#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"

# Function: Install Docker
install_docker() {
    show_brand
    section_header "Docker Installation"
    
    # Check if root
    check_root
    
    # Check internet connection
    if ! check_internet; then
        exit 1
    fi
    
    # Check if Docker is already installed
    if command_exists docker; then
        info_msg "Docker is already installed"
        docker_version=$(docker --version | cut -d ' ' -f3 | tr -d ',')
        info_msg "Current version: $docker_version"
        
        read -p "Do you want to reinstall Docker? (y/n): " choice
        if [[ ! $choice =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    # Detect OS
    os_info=$(check_os)
    distro=$(echo "$os_info" | cut -d':' -f1)
    version=$(echo "$os_info" | cut -d':' -f2)
    
    info_msg "Detected OS: $distro $version"
    
    # Install prerequisites
    install_packages ca-certificates curl gnupg lsb-release
    
    # Install Docker based on distribution
    case $distro in
        ubuntu|debian)
            # Remove old versions if any
            show_progress "Removing old Docker versions (if any)"
            apt-get remove -y docker docker-engine docker.io containerd runc >/dev/null 2>&1 || true
            complete_progress_success
            
            # Add Docker's official GPG key
            show_progress "Adding Docker's GPG key"
            mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$distro/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            complete_progress_success
            
            # Set up the repository
            show_progress "Setting up Docker repository"
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$distro $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            complete_progress_success
            
            # Install Docker Engine
            show_progress "Installing Docker Engine"
            apt-get update -qq >/dev/null
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null 2>&1
            complete_progress_success
            ;;
            
        centos|rhel|fedora|rocky|almalinux)
            # Remove old versions if any
            show_progress "Removing old Docker versions (if any)"
            yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine >/dev/null 2>&1 || true
            complete_progress_success
            
            # Set up the repository
            show_progress "Setting up Docker repository"
            if command_exists dnf; then
                dnf -y install dnf-plugins-core >/dev/null 2>&1
                dnf config-manager --add-repo https://download.docker.com/linux/$distro/docker-ce.repo >/dev/null
            else
                yum install -y yum-utils >/dev/null 2>&1
                yum-config-manager --add-repo https://download.docker.com/linux/$distro/docker-ce.repo >/dev/null
            fi
            complete_progress_success
            
            # Install Docker Engine
            show_progress "Installing Docker Engine"
            if command_exists dnf; then
                dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null 2>&1
            else
                yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null 2>&1
            fi
            complete_progress_success
            ;;
            
        *)
            error_msg "Unsupported distribution: $distro"
            exit 1
            ;;
    esac
    
    # Start and enable Docker service
    show_progress "Starting Docker service"
    systemctl start docker
    systemctl enable docker
    complete_progress_success
    
    # Verify installation
    if ! command_exists docker; then
        error_msg "Docker installation failed"
        exit 1
    fi
    
    # Add current user to docker group if not root
    if [ "$SUDO_USER" ]; then
        show_progress "Adding user $SUDO_USER to the docker group"
        usermod -aG docker "$SUDO_USER"
        complete_progress_success
        info_msg "Please log out and log back in for the group changes to take effect"
    fi
    
    # Display Docker version
    docker_version=$(docker --version | cut -d ' ' -f3 | tr -d ',')
    success_msg "Docker $docker_version installed successfully!"
    
    # Check if Docker Compose plugin is installed
    if command_exists docker-compose; then
        compose_version=$(docker-compose --version | cut -d ' ' -f3 | tr -d ',')
        success_msg "Docker Compose $compose_version is available"
    elif command_exists docker && docker compose version >/dev/null 2>&1; then
        compose_version=$(docker compose version --short)
        success_msg "Docker Compose Plugin $compose_version is available"
    else
        warning_msg "Docker Compose is not available"
    fi
    
    # Final instructions
    echo ""
    info_msg "You can verify the installation by running:"
    echo "  docker run hello-world"
    echo ""
    info_msg "For more information, visit:"
    echo "  https://docs.docker.com/"
}

# Run the main function
install_docker
