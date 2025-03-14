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

# Function: Check if the script is running as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        error_exit "This script must be run as root."
    fi
}

# Function: Check if a command is installed
check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

# Function: Initialize Docker
init_docker() {
    echo -e "${YELLOW}Updating package list...${NC}"
    apt-get update > /dev/null || error_exit "Failed to update package list"

    echo -e "${YELLOW}Installing necessary dependencies...${NC}"
    if ! check_command git; then
        echo -e "${YELLOW}Git not detected, installing...${NC}"
        apt install -y git || error_exit "Failed to install git"
    else
        echo -e "${GREEN}Git is already installed.${NC}"
    fi

    if ! check_command docker; then
        echo -e "${YELLOW}Docker not detected, installing...${NC}"

        apt install -y ca-certificates curl gnupg lsb-release || error_exit "Failed to install dependencies"

        # Add GPG key for Docker
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg || error_exit "Failed to add Docker GPG key"

        # Set the Docker repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || error_exit "Failed to set Docker repository"

        # Install the latest version of Docker
        apt-get install -y docker-ce docker-ce-cli containerd.io > /dev/null || error_exit "Failed to install Docker"

        success_msg "Docker installed successfully."
    else
        echo -e "${GREEN}Docker is already installed.${NC}"
    fi

    # Start Docker service
    systemctl start docker || error_exit "Failed to start Docker service"
    # Enable Docker to start on boot
    systemctl enable docker || error_exit "Failed to enable Docker service"
}

# Function: Initialize Ritual node
init_node() {
    init_docker

    echo -e "${GREEN}Next, you need to get the Identity code via https://test1.titannet.io/newoverview/activationcodemanagement.${NC}"
    read -p "Identity code: " identity_code

    # Prompt the user to set up the port
    read -p "Enter port: " port1

    # Prompt the RPC address
    read -p "Enter RPC address: " rpc_address

    # Prompt user to set up Docker Hub credentials
    read -p "Enter Docker Hub username: " username
    read -p "Enter Docker Hub password: " password

    # Pull the Docker image
    echo -e "${GREEN}Pulling Docker image...${NC}"
    docker pull nezha123/titan-edge || error_exit "Failed to pull Docker image"

    # Create your own volume
    mkdir -p ~/.titanedge

    # Run the Docker container
    echo -e "${GREEN}Running the Docker node...${NC}"
    docker run -d -v ~/.titanedge:/root/.titanedge nezha123/titan-edge || error_exit "Failed to run Docker container"

    # Get the container ID
    container_id=$(docker container ls | grep 'nezha123/titan-edge' | awk '{print $1}')

    echo "TitanNetwork's ContainerID is: $container_id"

    # Enter the container
    echo -e "${GREEN}Entering the container to set up...${NC}"
    docker exec -it "$container_id" /bin/bash || error_exit "Failed to enter the Docker container"

    titan-edge bind --hash="$identity_code" https://api-test1.container1.titannet.io/api/v2/device/binding || error_exit "Binding failed"

    success_msg "TitanNetwork's node installation completed."
}

# Function: View node logs
check_service_status() {
    echo -e "${GREEN}Checking service status...${NC}"
    docker compose logs -f || error_exit "Failed to check logs"
}

# Main function
main() {
    show_brand
    echo "Welcome to use this script to install Ritual's services."
    echo "================================================================"
    echo "Please select the operation to be performed:"
    echo "1. Install node"
    echo "2. View node logs"
    echo "3. Exit"
    read -p "Please enter an option (1-3): " OPTION

    case $OPTION in
    1) init_node;;
    2) check_service_status;;
    3) exit 0;;
    *) echo -e "${RED}Invalid option, please try again.${NC}";;
    esac
}

# Call main function
main
