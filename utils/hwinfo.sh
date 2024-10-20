#!/bin/bash

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Global variables
LOG_FILE=""

# Function: Display brand
show_brand() {
    local width=45  # Width of the brand display
    local stars=$(printf '%*s' "$width" | tr ' ' '*')
    
    echo -e "${YELLOW}"
    echo "$stars"
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
    echo "$stars"
    echo -e "${NC}"
    echo "Hardware Information Collection Tool"
    echo "Version: 1.0"
    echo "Copyright © $(date +%Y) Lebit.SH. All rights reserved."
    echo
}

# Function: Display privacy notice and get user consent
get_user_consent() {
    local proposed_log_file="/var/log/hwinfo_$(date +%Y%m%d_%H%M%S).log"
    
    echo -e "${YELLOW}Privacy Notice${NC}"
    echo "This script will collect hardware information from your system."
    echo "The following types of information will be collected:"
    echo "  - Server brand and model"
    echo "  - Serial number"
    echo "  - CPU information"
    echo "  - Motherboard details"
    echo "  - Memory configuration"
    echo "  - Disk and SMART information"
    echo "  - PCIe device details"
    echo "  - Power supply information"
    echo
    echo "This information will be saved locally in a log file: $proposed_log_file"
    echo "No data will be transmitted over the network."
    echo

    read -p "Do you consent to collecting this information? (y/n): " consent

    if [[ $consent =~ ^[Yy]$ ]]; then
        LOG_FILE="$proposed_log_file"
        return 0
    else
        echo -e "${RED}User did not provide consent. Exiting.${NC}"
        exit 1
    fi
}

# Function: Initialize log file
initialize_log_file() {
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"
    chown root:root "$LOG_FILE"
    log_message "INFO" "Log file initialized at $LOG_FILE"
}

# Function: Log messages
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
}

# Function: Log hardware information
log_hardware_info() {
    local section="$1"
    local info="$2"
    echo -e "\n[$section]" >> "$LOG_FILE"
    echo "$info" >> "$LOG_FILE"
}

# Function: Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function: Check for root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root${NC}" >&2
        exit 1
    fi
}

# Function: Install required packages
install_required_packages() {
    local packages=("dmidecode" "smartmontools" "pciutils")
    for package in "${packages[@]}"; do
        if ! command_exists "$package"; then
            log_message "INFO" "Installing $package"
            if command_exists apt-get; then
                apt-get update && apt-get install -y "$package"
            elif command_exists yum; then
                yum install -y "$package"
            else
                log_message "ERROR" "Unable to install $package. Package manager not found."
                echo -e "${RED}Unable to install $package. Package manager not found.${NC}" >&2
                exit 1
            fi
        fi
    done
}

# Function to get brand and model of server
get_brand_model_info() {
    local product_name
    local manufacturer
    product_name=$(dmidecode -t system | grep -i "product name" | awk -F ':' '{print $2}' | xargs)
    manufacturer=$(dmidecode -t system | grep -i "manufacturer" | awk -F ':' '{print $2}' | xargs)
    echo "${product_name}_${manufacturer}"
}

# Function to get serial number
get_serial_number() {
    dmidecode -t system | grep "Serial Number" | awk -F ':' '{print $2}' | xargs
}

# Function to get CPU information
get_cpu_info() {
    lscpu
}

# Function to get motherboard information
get_motherboard_info() {
    dmidecode -t baseboard
}

# Function to get memory information
get_memory_info() {
    free -h && echo "" && dmidecode -t memory
}

# Function to get disk and SMART information
get_disk_and_smart_info() {
    lsblk -d -o NAME,SIZE,MODEL,SERIAL && echo ""
    
    while read -r disk; do
        echo "Disk: $disk"
        smartctl -i "$disk" || log_message "ERROR" "smartctl info failed for $disk"
        smartctl -A "$disk" || log_message "ERROR" "smartctl attributes failed for $disk"
        echo ""
    done < <(lsblk -ndo NAME,TYPE | awk '$2=="disk"{print "/dev/"$1}')
}

# Function to get PCIe information
get_pcie_info() {
    lspci -nn -v
}

# Function to get power supply information
get_power_supply_info() {
    dmidecode -t 39
}

# Main execution
main() {
    show_brand
    check_root
    get_user_consent
    initialize_log_file
    install_required_packages

    log_message "INFO" "Starting hardware information collection"

    log_hardware_info "Server" "$(get_brand_model_info)"
    log_hardware_info "Serial Number" "$(get_serial_number)"
    log_hardware_info "CPU Info" "$(get_cpu_info)"
    log_hardware_info "Motherboard Info" "$(get_motherboard_info)"
    log_hardware_info "Memory Info" "$(get_memory_info)"
    log_hardware_info "Disk Info" "$(get_disk_and_smart_info)"
    log_hardware_info "PCIe Info" "$(get_pcie_info)"
    log_hardware_info "Power Supply Info" "$(get_power_supply_info)"

    log_message "INFO" "Hardware information collection completed"
    echo -e "${GREEN}Hardware information has been collected and saved to $LOG_FILE${NC}"
}

# Run main function
main