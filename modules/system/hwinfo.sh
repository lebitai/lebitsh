#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"

# Function: Initialize log file
initialize_log_file() {
    local log_file="$1"
    touch "$log_file"
    chmod 600 "$log_file"
    if [ "$SUDO_USER" ]; then
        chown "$SUDO_USER":"$SUDO_USER" "$log_file"
    else
        chown "$(whoami)":"$(whoami)" "$log_file"
    fi
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] Log file initialized at $log_file" >> "$log_file"
}

# Function: Log hardware information
log_hardware_info() {
    local log_file="$1"
    local section="$2"
    local info="$3"
    echo -e "\n[$section]" >> "$log_file"
    echo "$info" >> "$log_file"
}

# Function: Collect hardware information
collect_hardware_info() {
    show_brand
    section_header "Hardware Information Collection"
    
    # Check if root
    check_root
    
    # Create log file name with timestamp
    local log_file="/tmp/hwinfo_$(date +%Y%m%d_%H%M%S).log"
    
    # Display privacy notice
    echo -e "${YELLOW}Privacy Notice${NC}"
    echo "This tool will collect hardware information from your system."
    echo "The following types of information will be collected:"
    echo "  - Server brand and model"
    echo "  - CPU information"
    echo "  - Memory configuration"
    echo "  - Disk information"
    echo "  - Network configuration"
    echo "  - System information"
    echo ""
    echo "This information will be saved locally to: $log_file"
    echo "No data will be transmitted over the network."
    echo ""
    
    read -p "Do you consent to collecting this information? (y/n): " consent
    if [[ ! $consent =~ ^[Yy]$ ]]; then
        error_msg "User did not provide consent. Exiting."
        exit 1
    fi
    
    # Initialize log file
    initialize_log_file "$log_file"
    
    # Install required packages
    info_msg "Checking required packages..."
    local packages=("dmidecode" "smartmontools" "pciutils" "lshw")
    install_packages "${packages[@]}"
    
    info_msg "Collecting hardware information. This may take a few moments..."
    
    # Collect system information
    log_hardware_info "$log_file" "System" "$(dmidecode -t system 2>/dev/null)"
    log_hardware_info "$log_file" "CPU" "$(get_system_info cpu)"
    log_hardware_info "$log_file" "Memory" "$(get_system_info memory)"
    log_hardware_info "$log_file" "Disks" "$(get_system_info disk)"
    
    # Collect SMART info for each disk
    while read -r disk; do
        if [[ $disk == /dev/* ]]; then
            log_hardware_info "$log_file" "SMART Info: $disk" "$(get_system_info smart "$disk" 2>/dev/null || echo 'SMART data collection failed')"
        fi
    done < <(lsblk -ndo NAME,TYPE | awk '$2=="disk"{print "/dev/"$1}')
    
    log_hardware_info "$log_file" "PCI Devices" "$(get_system_info pci)"
    log_hardware_info "$log_file" "Network" "$(get_system_info network)"
    log_hardware_info "$log_file" "Operating System" "$(get_system_info os)"
    
    # Get additional hardware details using lshw if available
    if command_exists lshw; then
        log_hardware_info "$log_file" "Hardware Details" "$(lshw -short 2>/dev/null)"
    fi
    
    success_msg "Hardware information collection completed"
    success_msg "Report saved to: $log_file"
    
    # Ask if user wants to view the report
    read -p "Do you want to view the report now? (y/n): " view_report
    if [[ $view_report =~ ^[Yy]$ ]]; then
        less "$log_file"
    fi
}

# Run the main function
collect_hardware_info
