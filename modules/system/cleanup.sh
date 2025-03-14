#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"

# Function: Clean system
clean_system() {
    show_brand
    section_header "System Cleanup"
    
    # Check if root
    check_root
    
    # Display warning
    warning_msg "This utility will clean system caches, logs and temporary files."
    echo "This may free up disk space, but will not affect your personal files."
    echo ""
    
    read -p "Do you want to proceed with system cleanup? (y/n): " proceed
    if [[ ! $proceed =~ ^[Yy]$ ]]; then
        info_msg "Cleanup cancelled by user"
        exit 0
    fi
    
    # Get initial disk usage
    local initial_usage
    initial_usage=$(df -h / | awk 'NR==2 {print $5}')
    info_msg "Current disk usage: $initial_usage"
    
    # Perform system cleanup
    system_cleanup
    
    # Additional cleanup for Docker if installed
    if command_exists docker; then
        section_header "Docker Cleanup"
        
        read -p "Do you want to clean Docker resources too? (y/n): " clean_docker
        if [[ $clean_docker =~ ^[Yy]$ ]]; then
            show_progress "Removing unused Docker images"
            docker image prune -af >/dev/null 2>&1
            complete_progress_success
            
            show_progress "Removing unused Docker volumes"
            docker volume prune -f >/dev/null 2>&1
            complete_progress_success
            
            show_progress "Removing unused Docker networks"
            docker network prune -f >/dev/null 2>&1
            complete_progress_success
            
            show_progress "Removing unused containers"
            docker container prune -f >/dev/null 2>&1
            complete_progress_success
            
            success_msg "Docker cleanup completed"
        fi
    fi
    
    # Clean user caches if we're running as sudo
    if [ "$SUDO_USER" ]; then
        read -p "Do you want to clean user cache files too? (y/n): " clean_user_cache
        if [[ $clean_user_cache =~ ^[Yy]$ ]]; then
            show_progress "Cleaning user cache files"
            
            # Clean browser caches
            SUDO_HOME=$(eval echo ~"$SUDO_USER")
            
            # Clean various browser caches - be careful with these patterns
            find "$SUDO_HOME/.cache" -type f -delete >/dev/null 2>&1
            find "$SUDO_HOME/.thumbnails" -type f -delete >/dev/null 2>&1
            
            complete_progress_success
        fi
    fi
    
    # Get final disk usage
    local final_usage
    final_usage=$(df -h / | awk 'NR==2 {print $5}')
    success_msg "Cleanup completed"
    success_msg "Disk usage before: $initial_usage"
    success_msg "Disk usage after: $final_usage"
}

# Function: Perform deep system cleanup
deep_clean() {
    show_brand
    section_header "Deep System Cleanup"
    
    # Check if root
    check_root
    
    # Display warning
    warning_msg "CAUTION: Deep cleaning may remove important files if not used carefully."
    warning_msg "This includes old kernel versions, configuration backups, and more."
    echo "Only proceed if you understand the risks."
    echo ""
    
    read -p "Do you want to proceed with deep system cleanup? (y/n): " proceed
    if [[ ! $proceed =~ ^[Yy]$ ]]; then
        info_msg "Deep cleanup cancelled by user"
        exit 0
    fi
    
    # Get initial disk usage
    local initial_usage
    initial_usage=$(df -h / | awk 'NR==2 {print $5}')
    info_msg "Current disk usage: $initial_usage"
    
    # Perform regular system cleanup first
    system_cleanup
    
    # Perform deep cleaning
    section_header "Deep Cleaning"
    
    # Clean old kernels - handle different distros
    local os_info
    os_info=$(check_os)
    local distro
    distro=$(echo "$os_info" | cut -d':' -f1)
    
    if [[ "$distro" == "ubuntu" || "$distro" == "debian" ]]; then
        show_progress "Removing old kernel packages"
        apt-get autoremove --purge -y >/dev/null 2>&1
        complete_progress_success
    elif [[ "$distro" == "centos" || "$distro" == "rhel" || "$distro" == "fedora" ]]; then
        show_progress "Removing old kernel packages"
        if command_exists dnf; then
            dnf remove $(dnf repoquery --installonly --latest-limit=-1 -q) -y >/dev/null 2>&1
        else
            package-cleanup --oldkernels --count=1 -y >/dev/null 2>&1
        fi
        complete_progress_success
    fi
    
    # Clean apt/yum/dnf caches more aggressively
    show_progress "Deep cleaning package manager caches"
    if [[ "$distro" == "ubuntu" || "$distro" == "debian" ]]; then
        apt-get clean >/dev/null 2>&1
        rm -rf /var/lib/apt/lists/* >/dev/null 2>&1
    elif [[ "$distro" == "centos" || "$distro" == "rhel" || "$distro" == "fedora" ]]; then
        if command_exists dnf; then
            dnf clean all >/dev/null 2>&1
        else
            yum clean all >/dev/null 2>&1
        fi
        rm -rf /var/cache/yum/* >/dev/null 2>&1
    fi
    complete_progress_success
    
    # Clean system journal logs
    if command_exists journalctl; then
        show_progress "Cleaning system journal logs"
        journalctl --vacuum-time=3d >/dev/null 2>&1
        complete_progress_success
    fi
    
    # Get final disk usage
    local final_usage
    final_usage=$(df -h / | awk 'NR==2 {print $5}')
    success_msg "Deep cleanup completed"
    success_msg "Disk usage before: $initial_usage"
    success_msg "Disk usage after: $final_usage"
}

# Main function
main() {
    show_brand
    section_header "System Cleanup Utility"
    
    # Display menu options
    options=(
        "Standard Cleanup (safe)"
        "Deep Cleanup (use with caution)"
        "Exit"
    )
    
    show_menu "Select cleanup operation:" "${options[@]}"
    choice=$?
    
    case $choice in
        1)
            # Standard Cleanup
            clean_system
            ;;
        2)
            # Deep Cleanup
            deep_clean
            ;;
        3)
            # Exit
            exit 0
            ;;
        *)
            # Invalid option
            error_msg "Invalid option"
            exit 1
            ;;
    esac
}

# Run the main function
main
