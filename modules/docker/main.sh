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
            
            # Get operating system and architecture
            os_name=$(get_os_name)
            arch=$(get_docker_compose_arch)
            
            # Try to install Docker Compose
            compose_installed=false
            
            # Method 1: Try downloading standalone binary
            show_progress "Attempting to download Docker Compose standalone binary"
            
            # Get the correct download URL
            compose_url=$(get_docker_compose_url "${latest_version}")
            
            # Try downloading with the detected URL
            if [ -n "$compose_url" ]; then
                if curl -fsSL "$compose_url" -o /tmp/docker-compose-test 2>/dev/null; then
                    mv /tmp/docker-compose-test /usr/local/bin/docker-compose
                    chmod +x /usr/local/bin/docker-compose
                    complete_progress_success
                    compose_installed=true
                    success_msg "Docker Compose v${latest_version} standalone installed successfully"
                fi
            fi
            
            # Method 2: Install Docker Compose plugin via package manager
            if [ "$compose_installed" = false ]; then
                complete_progress_failure
                info_msg "Standalone binary download failed, installing Docker Compose plugin instead..."
                
                # Detect distribution and install accordingly
                if [ -f /etc/os-release ]; then
                    . /etc/os-release
                    distro=${ID,,}
                    
                    show_progress "Installing Docker Compose plugin via package manager"
                    
                    case $distro in
                        ubuntu|debian)
                            # Only try plugin installation on Linux
                            if [ "$os_name" = "linux" ]; then
                                apt-get update -y >/dev/null 2>&1
                                if apt-get install -y docker-compose-plugin >/dev/null 2>&1; then
                                    complete_progress_success
                                    compose_installed=true
                                    success_msg "Docker Compose plugin installed successfully via apt"
                                else
                                    complete_progress_failure
                                fi
                            else
                                complete_progress_failure
                                info_msg "Docker Compose plugin is not available for $os_name via apt"
                            fi
                            ;;
                        centos|rhel|fedora|rocky|almalinux)
                            # Only try plugin installation on Linux
                            if [ "$os_name" = "linux" ]; then
                                if command_exists dnf; then
                                    if dnf install -y docker-compose-plugin >/dev/null 2>&1; then
                                        complete_progress_success
                                        compose_installed=true
                                        success_msg "Docker Compose plugin installed successfully via dnf"
                                    else
                                        complete_progress_failure
                                    fi
                                else
                                    if yum install -y docker-compose-plugin >/dev/null 2>&1; then
                                        complete_progress_success
                                        compose_installed=true
                                        success_msg "Docker Compose plugin installed successfully via yum"
                                    else
                                        complete_progress_failure
                                    fi
                                fi
                            else
                                complete_progress_failure
                                info_msg "Docker Compose plugin is not available for $os_name via package manager"
                            fi
                            ;;
                    esac
                fi
            fi
            
            # Method 3: Install via Docker plugin manager
            if [ "$compose_installed" = false ] && command_exists docker; then
                show_progress "Attempting to install via Docker CLI plugin manager"
                
                # Create appropriate plugin directory based on OS
                if [ "$os_name" = "darwin" ]; then
                    # macOS plugin locations
                    plugin_dirs=(
                        "$HOME/.docker/cli-plugins"
                        "/usr/local/lib/docker/cli-plugins"
                    )
                else
                    # Linux plugin locations
                    plugin_dirs=(
                        "/usr/local/lib/docker/cli-plugins"
                        "$HOME/.docker/cli-plugins"
                    )
                fi
                
                # Try each plugin directory
                for plugin_dir in "${plugin_dirs[@]}"; do
                    # Create plugin directory if it doesn't exist
                    mkdir -p "$plugin_dir" 2>/dev/null || continue
                    
                    # Try to download to plugin directory
                    compose_cli_url=$(get_docker_compose_url "${latest_version}")
                    if curl -fsSL "$compose_cli_url" -o "$plugin_dir/docker-compose" 2>/dev/null; then
                        chmod +x "$plugin_dir/docker-compose"
                        complete_progress_success
                        compose_installed=true
                        success_msg "Docker Compose installed as Docker CLI plugin in $plugin_dir"
                        break
                    fi
                done
                
                if [ "$compose_installed" = false ]; then
                    complete_progress_failure
                fi
            fi
            
            # Verify installation
            if [ "$compose_installed" = true ]; then
                echo ""
                info_msg "Verifying Docker Compose installation..."
                
                if command -v docker-compose >/dev/null 2>&1; then
                    version=$(docker-compose --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
                    success_msg "Docker Compose standalone is available (version: $version)"
                    info_msg "Usage: docker-compose [command]"
                elif docker compose version >/dev/null 2>&1; then
                    version=$(docker compose version --short 2>/dev/null)
                    success_msg "Docker Compose plugin is available (version: $version)"
                    info_msg "Usage: docker compose [command] (no hyphen)"
                fi
            else
                error_msg "Failed to install Docker Compose using all available methods"
                info_msg "Please check your internet connection and try again"
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
