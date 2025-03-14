#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"

# Main function
dev_main() {
    show_brand
    section_header "Development Environment Tools"
    
    options=(
        "Install Golang"
        "Install Node.js (via NVM)"
        "Install Rust"
        "Install SQLite3"
        "Setup Quick Aliases"
        "Back to Main Menu"
    )
    
    while true; do
        show_menu "Select an option:" "${options[@]}"
        choice=$?
        
        case $choice in
            1)
                # Install Golang
                bash "${SCRIPT_DIR}/golang.sh"
                ;;
            2)
                # Install Node.js (via NVM)
                bash "${SCRIPT_DIR}/node.sh"
                ;;
            3)
                # Install Rust
                bash "${SCRIPT_DIR}/rust.sh"
                ;;
            4)
                # Install SQLite3
                bash "${SCRIPT_DIR}/sqlite.sh"
                ;;
            5)
                # Setup Quick Aliases
                bash "${SCRIPT_DIR}/quickalias.sh"
                ;;
            6)
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
dev_main
