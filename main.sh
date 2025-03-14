#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/common"
MODULES_DIR="${SCRIPT_DIR}/modules"

# Source common functions
source "${COMMON_DIR}/ui.sh"
source "${COMMON_DIR}/logging.sh"
source "${COMMON_DIR}/config.sh"
source "${COMMON_DIR}/utils.sh"

# Check if user is root or has sudo privileges
check_privileges() {
    if [ "$(id -u)" -ne 0 ]; then
        log_warn "Some functions require root privileges"
        log_info "Re-running with sudo..."
        
        # Re-run the script with sudo
        exec sudo "$0" "$@"
        exit $?
    fi
    
    log_debug "Running with root privileges"
}

# Display welcome message
welcome() {
    show_brand
    section_header "Linux System Initialization Toolkit"
    echo -e "Welcome to ${GREEN}Lebit.sh${NC} - Your Linux system initialization toolkit"
    echo ""
    echo "This toolkit helps you optimize, configure, and manage your Linux server."
    echo "Choose from the options below to get started."
    echo ""
    
    # Show system info if enabled in config
    if [[ "$(get_config show_system_info)" == "true" ]]; then
        show_system_info
    fi
}

# Configuration management
manage_config() {
    local options=(
        "View Current Configuration"
        "Edit Configuration"
        "Reset to Default Configuration"
        "Back to Main Menu"
    )
    
    while true; do
        show_menu "Configuration Management" "${options[@]}"
        local choice=$?
        
        case $choice in
            1)
                # View current configuration
                show_config
                ;;
            2)
                # Edit configuration
                edit_config
                ;;
            3)
                # Reset configuration
                reset_config
                ;;
            4)
                # Back to main menu
                return
                ;;
            *)
                error_msg "Invalid option"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        clear
        show_brand
    done
}

# Show logs
view_logs() {
    show_brand
    section_header "System Logs"
    
    local options=(
        "View Last 50 Log Entries"
        "View Last 100 Log Entries"
        "View Errors Only"
        "Clear Logs"
        "Back to Main Menu"
    )
    
    while true; do
        show_menu "Log Management" "${options[@]}"
        local choice=$?
        
        case $choice in
            1)
                # View last 50 logs
                show_logs 50
                ;;
            2)
                # View last 100 logs
                show_logs 100
                ;;
            3)
                # View errors only
                show_logs 1000 | grep -E "\[ERROR\]|\[CRITICAL\]"
                ;;
            4)
                # Clear logs
                clear_logs
                ;;
            5)
                # Back to main menu
                return
                ;;
            *)
                error_msg "Invalid option"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        clear
        show_brand
    done
}

# Main function
main() {
    # Clear screen
    clear
    
    # Check privileges
    check_privileges
    
    # Log application start
    log_info "Lebit.sh started (version: $(get_config LEBITSH_VERSION "1.0.0"))"
    
    # Display welcome message
    welcome
    
    # Main menu options
    options=(
        "System Management"
        "Docker Management"
        "Development Environment"
        "System Tools"
        "Mining Tools"
        "Configuration"
        "View Logs"
        "Exit"
    )
    
    while true; do
        show_menu "Select a category:" "${options[@]}"
        choice=$?
        
        case $choice in
            1)
                # System Management
                log_info "Loading System Management module"
                bash "${MODULES_DIR}/system/main.sh"
                ;;
            2)
                # Docker Management
                log_info "Loading Docker Management module"
                bash "${MODULES_DIR}/docker/main.sh"
                ;;
            3)
                # Development Environment
                log_info "Loading Development Environment module"
                bash "${MODULES_DIR}/dev/main.sh"
                ;;
            4)
                # System Tools
                log_info "Loading System Tools module"
                bash "${MODULES_DIR}/tools/main.sh"
                ;;
            5)
                # Mining Tools
                log_info "Loading Mining Tools module"
                bash "${MODULES_DIR}/mining/main.sh"
                ;;
            6)
                # Configuration Management
                log_info "Loading Configuration Management"
                manage_config
                ;;
            7)
                # View Logs
                log_info "Loading Log Viewer"
                view_logs
                ;;
            8)
                # Exit
                clear
                log_info "Exiting Lebit.sh"
                echo -e "Thank you for using ${GREEN}Lebit.sh${NC}!"
                echo "Visit https://lebit.sh for updates and documentation."
                exit 0
                ;;
            *)
                log_error "Invalid option selected"
                error_msg "Invalid option"
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
        clear
        welcome
    done
}

# Run the main function
main "$@"
