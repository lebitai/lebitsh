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

# Progress bar function
progress_bar() {
    local duration=$1
    local steps=$2
    local step_duration=$(echo "scale=2; $duration/$steps" | bc)
    for i in $(seq 1 $steps); do
        echo -ne "\r[${YELLOW}"
        printf '%*s' "$i" | tr ' ' '#'
        printf '%*s' "$((steps-i))" | tr ' ' ' '
        echo -ne "${NC}] $((i*100/steps))%"
        sleep $step_duration
    done
    echo
}

# Ensure script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run this script with root privileges${NC}"
    exit 1
fi

# Detect operating system
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    VER=$(lsb_release -sr)
else
    echo -e "${RED}Unable to detect operating system${NC}"
    exit 1
fi

# Function to check if Docker is installed
check_docker() {
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}Docker is already installed.${NC}"
        docker --version
        return 0
    else
        echo -e "${YELLOW}Docker is not installed.${NC}"
        return 1
    fi
}

# Function to check if Docker Compose is installed
check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        echo -e "${GREEN}Docker Compose is already installed.${NC}"
        docker-compose --version
        return 0
    else
        echo -e "${YELLOW}Docker Compose is not installed.${NC}"
        return 1
    fi
}

# Function to install Docker
install_docker() {
    echo -e "${YELLOW}Installing Docker...${NC}"
    progress_bar 10 20

    if [ "$OS" = "Ubuntu" ]; then
        apt-get install -y docker-ce docker-ce-cli containerd.io > /dev/null 2>&1
    elif [ "$OS" = "CentOS Linux" ]; then
        yum install -y docker-ce docker-ce-cli containerd.io > /dev/null 2>&1
    fi

    # Start Docker
    systemctl start docker
    # Enable Docker to start on boot
    systemctl enable docker

    # Verify Docker installation
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker installation failed${NC}"
        exit 1
    fi

    # Add current user to docker group
    usermod -aG docker $SUDO_USER
    echo -e "${GREEN}Docker installed successfully!${NC}"
    echo -e "${YELLOW}Please log out and log back in, or restart the system to apply changes.${NC}"
}

# Function to install Docker Compose
install_docker_compose() {
    echo -e "${YELLOW}Installing Docker Compose...${NC}"
    progress_bar 5 10

    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d '"' -f 4)
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}Docker Compose installation failed${NC}"
        exit 1
    fi

    echo -e "${GREEN}Docker Compose installed successfully!${NC}"
}

# Function to verify Docker and Docker Compose installation
verify_installation() {
    echo -e "${YELLOW}Verifying Docker and Docker Compose installation...${NC}"

    # Check Docker
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version)
        echo -e "${GREEN}Docker is installed: $DOCKER_VERSION${NC}"
        
        # Check if Docker daemon is running
        if systemctl is-active --quiet docker; then
            echo -e "${GREEN}Docker daemon is running${NC}"
        else
            echo -e "${RED}Docker daemon is not running${NC}"
        fi

        # Test Docker functionality
        if docker run hello-world | grep -q "Hello from Docker!"; then
            echo -e "${GREEN}Docker is functioning correctly${NC}"
        else
            echo -e "${RED}Docker test failed${NC}"
        fi
    else
        echo -e "${RED}Docker is not installed or not in PATH${NC}"
    fi

    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version)
        echo -e "${GREEN}Docker Compose is installed: $COMPOSE_VERSION${NC}"
    else
        echo -e "${RED}Docker Compose is not installed or not in PATH${NC}"
    fi
}

# Main function
main() {
    show_brand

    echo -e "${YELLOW}Checking existing Docker installation...${NC}"
    if check_docker; then
        echo -e "${GREEN}Docker is already installed. Skipping Docker installation.${NC}"
    else
        case $OS in
            "Ubuntu")
                echo -e "${YELLOW}Detected Ubuntu system, version: $VER${NC}"
                echo -e "${YELLOW}Updating package index...${NC}"
                apt-get update > /dev/null 2>&1
                progress_bar 5 10
                echo -e "${YELLOW}Installing necessary dependencies...${NC}"
                apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release > /dev/null 2>&1
                progress_bar 5 10
                echo -e "${YELLOW}Adding Docker's official GPG key...${NC}"
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg > /dev/null 2>&1
                progress_bar 3 10
                echo -e "${YELLOW}Setting up stable repository...${NC}"
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                progress_bar 2 10
                echo -e "${YELLOW}Updating package index again...${NC}"
                apt-get update > /dev/null 2>&1
                progress_bar 5 10
                install_docker
                ;;
            "CentOS Linux")
                echo -e "${YELLOW}Detected CentOS system, version: $VER${NC}"
                echo -e "${YELLOW}Installing necessary dependencies...${NC}"
                yum install -y yum-utils device-mapper-persistent-data lvm2 > /dev/null 2>&1
                progress_bar 10 20
                echo -e "${YELLOW}Setting up stable repository...${NC}"
                yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1
                progress_bar 5 10
                install_docker
                ;;
            *)
                echo -e "${RED}Unsupported operating system: $OS${NC}"
                exit 1
                ;;
        esac
    fi

    echo -e "${YELLOW}Checking existing Docker Compose installation...${NC}"
    if check_docker_compose; then
        echo -e "${GREEN}Docker Compose is already installed. Skipping Docker Compose installation.${NC}"
    else
        install_docker_compose
    fi

    # Verify the installation
    verify_installation

    echo -e "${YELLOW}Installation and verification complete.${NC}"
    echo -e "${YELLOW}You can run 'docker --version' and 'docker-compose --version' to verify the installation.${NC}"
}

# Call main function
main
