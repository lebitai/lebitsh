#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"
source "${COMMON_DIR}/logging.sh"

# Predefined aliases
declare -A PREDEFINED_ALIASES=(
    ["apt-up"]="apt update && apt upgrade -y"
    ["dfh"]="df -h"
    ["duh"]="du -h --max-depth=1"
    ["psa"]="ps aux"
    ["ll"]="ls -alF"
    ["la"]="ls -A"
    ["l"]="ls -CF"
    ["grep"]="grep --color=auto"
    ["fgrep"]="fgrep --color=auto"
    ["egrep"]="egrep --color=auto"
    [".."]="cd .."
    ["..."]="cd ../.."
    ["...."]="cd ../../.."
    ["h"]="history"
    ["j"]="jobs -l"
)

# Function to add alias to shell config
add_alias_to_config() {
    local alias_name="$1"
    local alias_command="$2"
    local config_file="$3"
    
    # Check if alias already exists
    if grep -q "alias ${alias_name}=" "$config_file" 2>/dev/null; then
        # Update existing alias
        sed -i "s/^alias ${alias_name}=.*/alias ${alias_name}='${alias_command}'/" "$config_file"
        log_info "Updated alias: ${alias_name}='${alias_command}'"
    else
        # Add new alias
        echo "alias ${alias_name}='${alias_command}'" >> "$config_file"
        log_info "Added alias: ${alias_name}='${alias_command}'"
    fi
}

# Function to apply aliases to current session
apply_aliases() {
    local config_file="$1"
    
    if [ -f "$config_file" ]; then
        source "$config_file"
        log_info "Applied aliases from $config_file"
    fi
}

# Function to setup predefined aliases
setup_predefined_aliases() {
    local shell_config="$HOME/.bashrc"
    
    # Check if we're using zsh
    if [ -n "$ZSH_VERSION" ]; then
        shell_config="$HOME/.zshrc"
    fi
    
    show_progress "Setting up predefined aliases"
    
    # Ensure config file exists
    if [ ! -f "$shell_config" ]; then
        touch "$shell_config"
    fi
    
    # Add each predefined alias
    for alias_name in "${!PREDEFINED_ALIASES[@]}"; do
        add_alias_to_config "$alias_name" "${PREDEFINED_ALIASES[$alias_name]}" "$shell_config"
    done
    
    # Apply aliases to current session
    apply_aliases "$shell_config"
    
    complete_progress_success
    success_msg "Predefined aliases have been set up"
    info_msg "You may need to restart your terminal or run 'source ${shell_config}' to see all changes"
}

# Function to add custom alias
add_custom_alias() {
    local shell_config="$HOME/.bashrc"
    
    # Check if we're using zsh
    if [ -n "$ZSH_VERSION" ]; then
        shell_config="$HOME/.zshrc"
    fi
    
    read -p "Enter alias name: " alias_name
    read -p "Enter command for alias: " alias_command
    
    if [ -n "$alias_name" ] && [ -n "$alias_command" ]; then
        add_alias_to_config "$alias_name" "$alias_command" "$shell_config"
        apply_aliases "$shell_config"
        success_msg "Custom alias '$alias_name' has been added"
    else
        error_msg "Alias name and command cannot be empty"
    fi
}

# Function to list current aliases
list_aliases() {
    local shell_config="$HOME/.bashrc"
    
    # Check if we're using zsh
    if [ -n "$ZSH_VERSION" ]; then
        shell_config="$HOME/.zshrc"
    fi
    
    section_header "Current Aliases"
    
    if [ -f "$shell_config" ]; then
        grep "^alias " "$shell_config" | sed 's/^alias //'
    else
        warning_msg "Config file not found: $shell_config"
    fi
}

# Function to remove an alias
remove_alias() {
    local shell_config="$HOME/.bashrc"
    
    # Check if we're using zsh
    if [ -n "$ZSH_VERSION" ]; then
        shell_config="$HOME/.zshrc"
    fi
    
    # Get list of current aliases
    local aliases=()
    if [ -f "$shell_config" ]; then
        while IFS= read -r line; do
            if [[ $line =~ ^alias\ ([^=]+)=.* ]]; then
                aliases+=("${BASH_REMATCH[1]}")
            fi
        done < <(grep "^alias " "$shell_config")
    fi
    
    if [ ${#aliases[@]} -eq 0 ]; then
        warning_msg "No aliases found"
        return
    fi
    
    # Show menu of aliases
    show_menu "Select alias to remove:" "${aliases[@]}" "Cancel"
    local choice=$?
    
    if [ $choice -ge 1 ] && [ $choice -le ${#aliases[@]} ]; then
        local alias_name="${aliases[$((choice-1))]}"
        
        if grep -q "^alias ${alias_name}=" "$shell_config"; then
            # Remove the alias
            sed -i "/^alias ${alias_name}=/d" "$shell_config"
            success_msg "Alias '$alias_name' has been removed"
            info_msg "You may need to restart your terminal or run 'unalias $alias_name' to see the change in current session"
        else
            error_msg "Alias '$alias_name' not found in config"
        fi
    elif [ $choice -eq $(( ${#aliases[@]} + 1 )) ]; then
        # Cancel
        return
    else
        error_msg "Invalid selection"
    fi
}

# Main function for alias management
alias_manager_main() {
    show_brand
    section_header "Alias Manager"
    
    while true; do
        options=(
            "Setup Predefined Aliases"
            "Add Custom Alias"
            "List Current Aliases"
            "Remove Alias"
            "Back to Main Menu"
        )
        
        show_menu "Select an option:" "${options[@]}"
        choice=$?
        
        case $choice in
            1)
                # Setup predefined aliases
                setup_predefined_aliases
                ;;
            2)
                # Add custom alias
                add_custom_alias
                ;;
            3)
                # List current aliases
                list_aliases
                ;;
            4)
                # Remove alias
                remove_alias
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
        section_header "Alias Manager"
    done
}

# If script is run directly, call main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    alias_manager_main
fi