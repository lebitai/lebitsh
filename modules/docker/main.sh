#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"

# Docker module main menu
docker_main() {
    show_brand
    section_header "Docker Management"
    
    # Display menu options
    options=(
        "Install Docker"
        "Upgrade Docker"
        "Configure Docker"
        "Docker System Prune"
        "Install Docker Compose"
        "Exit"
    )
    
    show_menu "Select a Docker operation:" "${options[@]}"
    choice=$?
    
    case $choice in
        1)
            # Install Docker
            "${SCRIPT_DIR}/install.sh"
            ;;
        2)
            # Upgrade Docker
            "${SCRIPT_DIR}/upgrade.sh"
            ;;
        3)
            # Configure Docker
            info_msg "This feature is coming soon!"
            read -p "Press Enter to continue..."
            docker_main
            ;;
        4)
            # Docker System Prune
            show_brand
            section_header "Docker System Prune"
            
            warning_msg "This will remove all unused containers, networks, images (both dangling and unreferenced), and optionally, volumes."
            read -p "Do you want to continue? (y/n): " confirm
            
            if [[ $confirm =~ ^[Yy]$ ]]; then
                read -p "Do you want to remove volumes too? (y/n): " volumes
                
                if [[ $volumes =~ ^[Yy]$ ]]; then
                    docker system prune -a --volumes -f
                else
                    docker system prune -a -f
                fi
                
                success_msg "Docker system pruned successfully"
            fi
            
            read -p "Press Enter to continue..."
            docker_main
            ;;
        5)
            # Install Docker Compose
            show_brand
            section_header "Install Docker Compose"
            
            # Check if Docker Compose is already installed
            if command_exists docker-compose; then
                compose_version=$(docker-compose --version | cut -d ' ' -f3 | tr -d ',')
                info_msg "Docker Compose is already installed (version: $compose_version)"
                read -p "Do you want to reinstall Docker Compose? (y/n): " choice
                if [[ ! $choice =~ ^[Yy]$ ]]; then
                    docker_main
                    return
                fi
            elif command_exists docker && docker compose version >/dev/null 2>&1; then
                compose_version=$(docker compose version --short)
                info_msg "Docker Compose Plugin is already installed (version: $compose_version)"
                read -p "Do you want to continue? (y/n): " choice
                if [[ ! $choice =~ ^[Yy]$ ]]; then
                    docker_main
                    return
                fi
            fi
            
            # Check root
            check_root
            
            # Install Docker Compose
            show_progress "Installing Docker Compose"
            
            # Get latest Docker Compose version
            latest_version=$(get_github_latest_version "docker/compose")
            
            if [ -z "$latest_version" ]; then
                latest_version="2.24.0" # Fallback version
            fi
            
            # Get system architecture
            arch=$(get_arch)
            
            # Download and install Docker Compose
            # Try new naming format first (v2.x)
            compose_url="https://github.com/docker/compose/releases/download/v${latest_version}/docker-compose-linux-${arch}"
            
            show_progress "Downloading Docker Compose v${latest_version}"
            if curl -fsSL "$compose_url" -o /usr/local/bin/docker-compose 2>/dev/null; then
                chmod +x /usr/local/bin/docker-compose
                complete_progress_success
                success_msg "Docker Compose v${latest_version} installed successfully"
            else
                # Try alternative URL format
                compose_url="https://github.com/docker/compose/releases/download/${latest_version}/docker-compose-linux-${arch}"
                if curl -fsSL "$compose_url" -o /usr/local/bin/docker-compose 2>/dev/null; then
                    chmod +x /usr/local/bin/docker-compose
                    complete_progress_success
                    success_msg "Docker Compose v${latest_version} installed successfully"
                else
                    complete_progress_failure
                    error_msg "Failed to download Docker Compose"
                    info_msg "You can install Docker Compose plugin instead:"
                    echo "  sudo apt-get update && sudo apt-get install docker-compose-plugin"
                    echo "  # or"
                    echo "  sudo yum install docker-compose-plugin"
                fi
            fi
            
            read -p "Press Enter to continue..."
            docker_main
            ;;
        6)
            # Exit
            exit 0
            ;;
        *)
            # Invalid option
            error_msg "Invalid option"
            read -p "Press Enter to continue..."
            docker_main
            ;;
    esac
}

# Run the main function
docker_main
