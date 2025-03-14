#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"

# Main function
system_main() {
    show_brand
    section_header "System Management"
    
    options=(
        "Hardware Information"
        "System Cleanup"
        "Time Synchronization"
        "Back to Main Menu"
    )
    
    while true; do
        show_menu "Select an option:" "${options[@]}"
        choice=$?
        
        case $choice in
            1)
                # Hardware Information
                bash "${SCRIPT_DIR}/hwinfo.sh"
                ;;
            2)
                # System Cleanup
                bash "${SCRIPT_DIR}/cleanup.sh"
                ;;
            3)
                # Time Synchronization
                bash "${SCRIPT_DIR}/sync_time.sh"
                ;;
            4)
                # Back to Main Menu
                return
                ;;
            *)
                error_msg "Invalid option"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        clear
    done
}

# Run the main function
system_main
