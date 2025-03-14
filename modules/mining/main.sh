#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"

# Main function
mining_main() {
    show_brand
    section_header "Cryptocurrency Mining Tools"
    
    options=(
        "EthStorage Mining"
        "Ritual Mining"
        "TitanNetwork Mining"
        "Back to Main Menu"
    )
    
    while true; do
        show_menu "Select a mining option:" "${options[@]}"
        choice=$?
        
        case $choice in
            1)
                # EthStorage Mining
                bash "${SCRIPT_DIR}/EthStorage/install.sh"
                ;;
            2)
                # Ritual Mining
                bash "${SCRIPT_DIR}/Ritual/install.sh"
                ;;
            3)
                # TitanNetwork Mining
                bash "${SCRIPT_DIR}/TitanNetwork/install.sh"
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
mining_main
