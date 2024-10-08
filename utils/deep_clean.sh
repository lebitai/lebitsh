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

# Function: Check root privileges
check_root() {
    if [ "$(id -u)" != "0" ]; then
        error_exit "This script must be run with root privileges"
    fi
}

# Function: Update and upgrade system
update_upgrade_system() {
    echo "Updating package list..."
    apt update || error_exit "Failed to update package list"
    
    echo "Upgrading installed packages..."
    apt upgrade -y || error_exit "Failed to upgrade packages"
    
    echo "Removing unnecessary packages..."
    apt autoremove -y || error_exit "Failed to remove unnecessary packages"
    
    echo "Cleaning APT cache..."
    apt clean || error_exit "Failed to clean APT cache"
}

# Function: Clean user trash
clean_trash() {
    echo "Emptying trash for all users..."
    rm -rf /home/*/.local/share/Trash/*/**
    rm -rf /root/.local/share/Trash/*/**
}

# Function: Remove old kernels
remove_old_kernels() {
    echo "Removing old kernels..."
    dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | xargs apt -y purge
}

# Function: Clean system logs and temporary files
clean_logs_and_temp() {
    echo "Cleaning system logs..."
    journalctl --vacuum-time=3d
    
    echo "Cleaning temporary files..."
    rm -rf /tmp/*
    
    echo "Cleaning thumbnail cache..."
    rm -rf /home/*/.cache/thumbnails/*
    rm -rf /root/.cache/thumbnails/*
    
    echo "Cleaning old log files..."
    find /var/log -type f \( -name "*.gz" -o -name "*.1" -o -name "*.old" \) -delete
}

# Function: Clean snap packages
clean_snap() {
    if command -v snap &> /dev/null; then
        echo "Cleaning old snap versions..."
        snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
            snap remove "$snapname" --revision="$revision"
        done
    fi
}

# Function: Clean Docker
clean_docker() {
    if command -v docker &> /dev/null; then
        echo "Cleaning Docker system..."
        docker system prune -af --volumes
    fi
}

# Function: Clean user cache
clean_user_cache() {
    echo "Cleaning user cache files..."
    find /home/* -type f \( -name '*.tmp' -o -name '*.temp' -o -name '*.swp' -o -name '*~' \) -delete
}

# Function: Display disk usage
show_disk_usage() {
    echo "Current disk usage:"
    df -h
}

# Main function
main() {
    show_brand
    check_root
    
    echo "Starting deep clean of the system..."
    
    update_upgrade_system
    clean_trash
    remove_old_kernels
    clean_logs_and_temp
    clean_snap
    clean_docker
    clean_user_cache
    
    success_msg "System cleaning completed."
    show_disk_usage
}

# Call main function
main
