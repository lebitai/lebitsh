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

# Function: Add custom alias
add_custom_alias() {
    local shell_rc=""
    local alias_name=""
    local alias_command=""

    # Determine the shell configuration file
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    else
        error_exit "Unsupported shell. Please use Bash or Zsh."
    fi

    # Get alias name from user
    while true; do
        read -p "Enter the alias name (e.g., apt-up): " alias_name
        if [[ -z "$alias_name" ]]; then
            echo -e "${YELLOW}Alias name cannot be empty. Please try again.${NC}"
        elif [[ "$alias_name" =~ [[:space:]] ]]; then
            echo -e "${YELLOW}Alias name cannot contain spaces. Please try again.${NC}"
        else
            break
        fi
    done

    # Get alias command from user
    while true; do
        read -p "Enter the command for the alias: " alias_command
        if [[ -z "$alias_command" ]]; then
            echo -e "${YELLOW}Command cannot be empty. Please try again.${NC}"
        else
            echo -e "${YELLOW}You entered: $alias_command${NC}"
            read -p "Is this correct? (y/n): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                break
            else
                echo "Please enter the command again."
            fi
        fi
    done

    # Check if alias already exists
    if grep -q "alias $alias_name=" "$shell_rc"; then
        echo -e "${YELLOW}Alias '$alias_name' already exists in $shell_rc${NC}"
        read -p "Do you want to update it? (y/n): " update_choice
        if [[ $update_choice =~ ^[Yy]$ ]]; then
            sed -i "/alias $alias_name=/c\alias $alias_name='$alias_command'" "$shell_rc"
            success_msg "Alias '$alias_name' updated in $shell_rc"
        else
            echo "Alias not updated."
        fi
    else
        echo "alias $alias_name='$alias_command'" >> "$shell_rc"
        success_msg "Alias '$alias_name' added to $shell_rc"
    fi

    echo -e "${YELLOW}Please run 'source $shell_rc' or start a new terminal session to apply the changes.${NC}"
}

# Function: Initialize environment
init_env() {
    echo "Initializing environment..."
    add_custom_alias
}

# Main function
main() {
    show_brand
    echo "Welcome to LEBIT.SH Environment Initialization Script"
    echo "======================================================"

    while true; do
        echo -e "${YELLOW}Please select the operation to be performed:${NC}"
        echo "1. Initialize environment (add custom alias)"
        echo "2. Exit"
        
        read -p "Please enter an option (1-2): " option
        case $option in
            1) init_env; break ;;
            2) echo "Exiting..."; exit 0 ;;
            *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
        esac
    done
}

# Call main function
main
