#!/bin/bash

# Import UI functions
# Get the directory where this script is located
if command -v realpath >/dev/null 2>&1; then
    SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
else
    # Fallback for macOS and systems without realpath
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
source "${SCRIPT_DIR}/ui.sh"

# Import logging functions if available
if [[ -f "${SCRIPT_DIR}/logging.sh" ]]; then
    source "${SCRIPT_DIR}/logging.sh"
fi

# Set default variables
LEBITSH_VERSION="1.0.0"
LEBITSH_TEMP_DIR="/tmp/lebitsh"

# Function: Check if the script is running as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        if [[ -n "$LOGGING_SOURCED" ]]; then
            log_error "This script must be run as root"
            log_info "Please run with sudo or as root user"
        else
            error_msg "This script must be run as root"
            info_msg "Please run with sudo or as root user"
        fi
        exit 1
    fi
    
    if [[ -n "$LOGGING_SOURCED" ]]; then
        log_debug "Running as root"
    fi
}

# Function: Check OS distribution and version
check_os() {
    # Check if it's Linux
    if [[ "$(uname)" != "Linux" ]]; then
        if [[ -n "$LOGGING_SOURCED" ]]; then
            log_error "This script is designed for Linux systems only"
        else
            error_msg "This script is designed for Linux systems only"
        fi
        exit 1
    fi
    
    # Detect distribution
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        DISTRO=$(lsb_release -si)
        VERSION=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # shellcheck disable=SC1091
        source /etc/lsb-release
        DISTRO=$DISTRIB_ID
        VERSION=$DISTRIB_RELEASE
    else
        if [[ -n "$LOGGING_SOURCED" ]]; then
            log_error "Unsupported Linux distribution"
        else
            error_msg "Unsupported Linux distribution"
        fi
        exit 1
    fi
    
    # Convert to lowercase
    DISTRO=$(echo "$DISTRO" | tr '[:upper:]' '[:lower:]')
    
    if [[ -n "$LOGGING_SOURCED" ]]; then
        log_info "Detected OS: $DISTRO:$VERSION"
    fi
    
    echo "$DISTRO:$VERSION"
}

# Function: Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function: Check internet connection
check_internet() {
    show_progress "Checking internet connection"
    if ping -c 1 google.com >/dev/null 2>&1; then
        complete_progress_success
        return 0
    else
        complete_progress_failure
        if [[ -n "$LOGGING_SOURCED" ]]; then
            log_error "No internet connection detected"
        else
            error_msg "No internet connection detected"
        fi
        return 1
    fi
}

# Function: Get latest version from GitHub
get_github_latest_version() {
    local repo="$1"
    local version
    
    if ! command_exists curl; then
        if [[ -n "$LOGGING_SOURCED" ]]; then
            log_error "curl is required but not installed"
        else
            error_msg "curl is required but not installed"
        fi
        return 1
    fi
    
    # Use portable approach that works on Ubuntu, CentOS, and macOS
    version=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | 
              grep '"tag_name"' | 
              sed -E 's/.*"tag_name": "([^"]+)".*/\1/' | 
              sed 's/^v//')
    
    if [ -z "$version" ]; then
        if [[ -n "$LOGGING_SOURCED" ]]; then
            log_error "Failed to get latest version for $repo"
        else
            error_msg "Failed to get latest version for $repo"
        fi
        return 1
    fi
    
    echo "$version"
}

# Function: Install required packages
install_packages() {
    local packages=("$@")
    local os_info
    
    os_info=$(check_os)
    local distro
    distro=$(echo "$os_info" | cut -d':' -f1)
    
    show_progress "Installing required packages: ${packages[*]}"
    
    case $distro in
        ubuntu|debian)
            apt-get update -qq >/dev/null
            apt-get install -y "${packages[@]}" >/dev/null 2>&1
            ;;
        centos|rhel|fedora|rocky|almalinux)
            if command_exists dnf; then
                dnf install -y "${packages[@]}" >/dev/null 2>&1
            else
                yum install -y "${packages[@]}" >/dev/null 2>&1
            fi
            ;;
        *)
            complete_progress_failure
            if [[ -n "$LOGGING_SOURCED" ]]; then
                log_error "Unsupported distribution: $distro"
            else
                error_msg "Unsupported distribution: $distro"
            fi
            return 1
            ;;
    esac
    
    for pkg in "${packages[@]}"; do
        if ! command_exists "$pkg"; then
            complete_progress_failure
            if [[ -n "$LOGGING_SOURCED" ]]; then
                log_error "Failed to install $pkg"
            else
                error_msg "Failed to install $pkg"
            fi
            return 1
        fi
    done
    
    complete_progress_success
    return 0
}

# Function: Create temporary directory
create_temp_dir() {
    mktemp -d "/tmp/lebitsh.XXXXXX"
}

# Function: Cleanup function
cleanup() {
    local temp_dir="$1"
    
    if [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
    fi
}

# Function: Download file
download_file() {
    local url="$1"
    local output="$2"
    
    show_progress "Downloading from $url"
    
    if command_exists curl; then
        if curl -fsSL "$url" -o "$output"; then
            complete_progress_success
            return 0
        else
            complete_progress_failure
            return 1
        fi
    elif command_exists wget; then
        if wget -q "$url" -O "$output"; then
            complete_progress_success
            return 0
        else
            complete_progress_failure
            return 1
        fi
    else
        complete_progress_failure "neither curl nor wget is available"
        if [[ -n "$LOGGING_SOURCED" ]]; then
            log_error "neither curl nor wget is available"
        else
            error_msg "neither curl nor wget is available"
        fi
        return 1
    fi
}

# Function: Get system architecture
get_arch() {
    local arch
    arch=$(uname -m)
    
    case $arch in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l)
            echo "armhf"
            ;;
        *)
            echo "$arch"
            ;;
    esac
}

# Function: Get Docker Compose architecture (different naming convention)
get_docker_compose_arch() {
    local arch
    arch=$(uname -m)
    
    case $arch in
        x86_64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "aarch64"  # Docker Compose uses aarch64 instead of arm64
            ;;
        armv7l)
            echo "armv7"
            ;;
        *)
            echo "$arch"
            ;;
    esac
}

# Function: Get operating system name for Docker Compose
get_os_name() {
    local os
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    
    case $os in
        linux)
            echo "linux"
            ;;
        darwin)
            echo "darwin"
            ;;
        *)
            echo "$os"
            ;;
    esac
}

# Function: Get Docker Compose download URL
get_docker_compose_url() {
    local version="$1"
    local os_name
    local arch
    
    os_name=$(get_os_name)
    arch=$(get_docker_compose_arch)
    
    # Try to get the exact URL from GitHub API
    local api_url="https://api.github.com/repos/docker/compose/releases/tags/v${version}"
    local asset_name="docker-compose-${os_name}-${arch}"
    
    local download_url
    download_url=$(curl -s "$api_url" | 
                   grep -E "browser_download_url.*${asset_name}\"" | 
                   sed -E 's/.*"browser_download_url": "([^"]+)".*/\1/' | 
                   head -1)
    
    if [ -n "$download_url" ]; then
        echo "$download_url"
    else
        # Fallback to constructed URL
        echo "https://github.com/docker/compose/releases/download/v${version}/docker-compose-${os_name}-${arch}"
    fi
}

# Function: Check minimum system requirements
check_system_requirements() {
    local min_ram="$1" # in MB
    arch=$(uname -m)
    
    case $arch in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "aarch64"
            ;;
        armv7l|armv7)
            echo "armv7"
            ;;
        armv6l|armv6)
            echo "armv6"
            ;;
        *)
            echo "$arch"
            ;;
    esac
}

# Function: Get Docker Compose download URL from GitHub
get_docker_compose_url() {
    local system arch binary_name download_url
    
    system=$(uname -s | tr '[:upper:]' '[:lower:]')
    arch=$(get_docker_compose_arch)
    binary_name="docker-compose-${system}-${arch}"
    
    # Get download URL from GitHub API
    download_url=$(curl -s "https://api.github.com/repos/docker/compose/releases/latest" | \
        grep -E "\"browser_download_url\".*${binary_name}\"" | \
        sed 's/.*"browser_download_url": "\(.*\)"/\1/' | \
        head -1)
    
    if [ -n "$download_url" ]; then
        echo "$download_url"
        return 0
    else
        return 1
    fi
}

# Function: Check minimum system requirements
check_system_requirements() {
    local min_ram="$1" # in MB
    local min_disk="$2" # in MB
    local min_cpu="$3" # number of cores
    
    # Check RAM
    local total_ram
    total_ram=$(free -m | awk '/^Mem:/{print $2}')
    
    if [ "$total_ram" -lt "$min_ram" ]; then
        if [[ -n "$LOGGING_SOURCED" ]]; then
            log_warning "System has less than recommended RAM ($total_ram MB < $min_ram MB)"
        else
            warning_msg "System has less than recommended RAM ($total_ram MB < $min_ram MB)"
        fi
    fi
    
    # Check disk space
    local free_disk
    free_disk=$(df -m / | awk 'NR==2{print $4}')
    
    if [ "$free_disk" -lt "$min_disk" ]; then
        if [[ -n "$LOGGING_SOURCED" ]]; then
            log_warning "System has less than recommended free disk space ($free_disk MB < $min_disk MB)"
        else
            warning_msg "System has less than recommended free disk space ($free_disk MB < $min_disk MB)"
        fi
    fi
    
    # Check CPU cores
    local cpu_cores
    cpu_cores=$(nproc)
    
    if [ "$cpu_cores" -lt "$min_cpu" ]; then
        if [[ -n "$LOGGING_SOURCED" ]]; then
            log_warning "System has less than recommended CPU cores ($cpu_cores < $min_cpu)"
        else
            warning_msg "System has less than recommended CPU cores ($cpu_cores < $min_cpu)"
        fi
    fi
}

# Function: Add a cron job
add_cron_job() {
    local cron_command="$1"
    local cron_schedule="$2"
    local cron_job="${cron_schedule} ${cron_command}"
    
    show_progress "Adding cron job"
    
    # Check if crontab already contains this job
    if crontab -l 2>/dev/null | grep -Fq "$cron_job"; then
        complete_progress_success "cron job already exists"
        return 0
    fi
    
    # Add the cron job
    (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
    
    if [ $? -eq 0 ]; then
        complete_progress_success
        return 0
    else
        complete_progress_failure
        if [[ -n "$LOGGING_SOURCED" ]]; then
            log_error "Failed to add cron job"
        else
            error_msg "Failed to add cron job"
        fi
        return 1
    fi
}

# Function: Get hardware information
get_system_info() {
    local info_type="$1"
    
    case $info_type in
        cpu)
            lscpu
            ;;
        memory)
            free -h && echo "" && dmidecode -t memory 2>/dev/null
            ;;
        disk)
            lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,MODEL,SERIAL 2>/dev/null
            ;;
        smart)
            local disk="$2"
            if [ -z "$disk" ]; then
                if [[ -n "$LOGGING_SOURCED" ]]; then
                    log_error "Disk device not specified for SMART info"
                else
                    error_msg "Disk device not specified for SMART info"
                fi
                return 1
            fi
            if command_exists smartctl; then
                smartctl -i "$disk" && smartctl -A "$disk" && smartctl -H "$disk"
            else
                if [[ -n "$LOGGING_SOURCED" ]]; then
                    log_error "smartctl not available. Install smartmontools package"
                else
                    error_msg "smartctl not available. Install smartmontools package"
                fi
                return 1
            fi
            ;;
        pci)
            lspci
            ;;
        network)
            ip -c a && echo "" && route -n
            ;;
        os)
            cat /etc/*release
            ;;
        kernel)
            uname -a
            ;;
        all)
            echo "===== CPU Info ====="
            get_system_info cpu
            echo -e "\n===== Memory Info ====="
            get_system_info memory
            echo -e "\n===== Disk Info ====="
            get_system_info disk
            echo -e "\n===== Network Info ====="
            get_system_info network
            echo -e "\n===== OS Info ====="
            get_system_info os
            echo -e "\n===== Kernel Info ====="
            get_system_info kernel
            ;;
        *)
            if [[ -n "$LOGGING_SOURCED" ]]; then
                log_error "Unknown info type: $info_type"
            else
                error_msg "Unknown info type: $info_type"
            fi
            return 1
            ;;
    esac
    
    return 0
}

# Function: System cleanup
system_cleanup() {
    show_progress "Cleaning package caches"
    
    local os_info
    os_info=$(check_os)
    local distro
    distro=$(echo "$os_info" | cut -d':' -f1)
    
    case $distro in
        ubuntu|debian)
            apt-get clean >/dev/null 2>&1
            apt-get autoremove -y >/dev/null 2>&1
            ;;
        centos|rhel|fedora|rocky|almalinux)
            if command_exists dnf; then
                dnf clean all >/dev/null 2>&1
                dnf autoremove -y >/dev/null 2>&1
            else
                yum clean all >/dev/null 2>&1
                yum autoremove -y >/dev/null 2>&1
            fi
            ;;
    esac
    
    complete_progress_success
    
    show_progress "Clearing log files"
    find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; >/dev/null 2>&1
    find /var/log -type f -name "*.log.*" -exec rm -f {} \; >/dev/null 2>&1
    complete_progress_success
    
    show_progress "Clearing temporary files"
    rm -rf /tmp/* /var/tmp/* >/dev/null 2>&1
    complete_progress_success
    
    return 0
}

# Function: Check and sync system time
sync_system_time() {
    show_progress "Checking NTP service"
    
    local os_info
    os_info=$(check_os)
    local distro
    distro=$(echo "$os_info" | cut -d':' -f1)
    
    # Install NTP packages if needed
    case $distro in
        ubuntu|debian)
            if ! command_exists ntpdate; then
                apt-get update -qq >/dev/null
                apt-get install -y ntpdate >/dev/null 2>&1
            fi
            ;;
        centos|rhel|fedora|rocky|almalinux)
            if ! command_exists ntpdate; then
                if command_exists dnf; then
                    dnf install -y ntpdate >/dev/null 2>&1
                else
                    yum install -y ntpdate >/dev/null 2>&1
                fi
            fi
            ;;
    esac
    
    complete_progress_success
    
    show_progress "Syncing system time"
    ntpdate -u pool.ntp.org >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        complete_progress_success
        return 0
    else
        complete_progress_failure
        if [[ -n "$LOGGING_SOURCED" ]]; then
            log_error "Failed to sync system time"
        else
            error_msg "Failed to sync system time"
        fi
        return 1
    fi
}
