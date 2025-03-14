#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"

# Main function
tools_main() {
    show_brand
    section_header "System Tools"
    
    options=(
        "SSL Certificate Renewal"
        "Back to Main Menu"
    )
    
    while true; do
        show_menu "Select an option:" "${options[@]}"
        choice=$?
        
        case $choice in
            1)
                # SSL Certificate Renewal
                bash "${SCRIPT_DIR}/renew_ssl.sh"
                ;;
            2)
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
tools_main
