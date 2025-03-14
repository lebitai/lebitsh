#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"

# Function: Install Rust
install_rust() {
    show_brand
    section_header "Rust Installation"
    
    # Check internet connection
    if ! check_internet; then
        exit 1
    fi
    
    # Determine the user home directory
    if [ "$SUDO_USER" ]; then
        user_home=$(eval echo ~"$SUDO_USER")
        actual_user="$SUDO_USER"
    else
        user_home="$HOME"
        actual_user="$(whoami)"
    fi
    
    # Check if Rust is already installed
    if [ -d "$user_home/.cargo" ] && [ -d "$user_home/.rustup" ]; then
        info_msg "Rust appears to be already installed"
        
        # Check Rust version if rustc is available
        if command -v rustc >/dev/null 2>&1; then
            rust_version=$(rustc --version 2>/dev/null)
            if [ -n "$rust_version" ]; then
                info_msg "Current version: $rust_version"
            fi
        fi
        
        read -p "Do you want to update or reinstall Rust? (y/n): " choice
        if [[ ! $choice =~ ^[Yy]$ ]]; then
            info_msg "You can manage Rust components using rustup"
            info_msg "To update Rust, run: rustup update"
            exit 0
        fi
        
        # Ask if user wants to update or reinstall
        options=("Update existing installation" "Reinstall from scratch" "Cancel")
        show_menu "Choose an option:" "${options[@]}"
        rust_choice=$?
        
        case $rust_choice in
            1)
                # Update Rust
                show_progress "Updating Rust"
                if [ "$SUDO_USER" ]; then
                    su - "$SUDO_USER" -c "rustup update" >/dev/null 2>&1
                else
                    rustup update >/dev/null 2>&1
                fi
                
                if [ $? -eq 0 ]; then
                    complete_progress_success
                    success_msg "Rust updated successfully"
                else
                    complete_progress_failure
                    error_msg "Failed to update Rust"
                fi
                exit 0
                ;;
            2)
                # Reinstall from scratch - continue with installation
                show_progress "Removing existing Rust installation"
                if [ "$SUDO_USER" ]; then
                    su - "$SUDO_USER" -c "rustup self uninstall -y" >/dev/null 2>&1
                else
                    rustup self uninstall -y >/dev/null 2>&1
                fi
                rm -rf "$user_home/.cargo" "$user_home/.rustup" 2>/dev/null
                complete_progress_success
                ;;
            3|*)
                # Cancel
                exit 0
                ;;
        esac
    fi
    
    # Install prerequisites
    if [ "$(id -u)" -eq 0 ]; then
        info_msg "Installing prerequisites..."
        install_packages curl gcc g++ make
    fi
    
    # Install Rust using rustup
    info_msg "Installing Rust using rustup..."
    
    # Create a temporary script to run rustup-init
    tmp_script=$(mktemp)
    cat << 'EOF' > "$tmp_script"
#!/bin/bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
EOF
    chmod +x "$tmp_script"
    
    show_progress "Downloading and installing Rust"
    if [ "$SUDO_USER" ]; then
        # Run as the sudo user, not as root
        su - "$SUDO_USER" -c "$tmp_script" >/dev/null 2>&1
    else
        # Run as current user
        bash "$tmp_script" >/dev/null 2>&1
    fi
    
    # Clean up temporary script
    rm -f "$tmp_script"
    
    # Source cargo environment
    if [ -f "$user_home/.cargo/env" ]; then
        if [ "$SUDO_USER" ]; then
            su - "$SUDO_USER" -c "source \"$user_home/.cargo/env\""
        else
            source "$user_home/.cargo/env"
        fi
        
        # Verify installation
        if [ "$SUDO_USER" ]; then
            rust_version=$(su - "$SUDO_USER" -c "rustc --version" 2>/dev/null)
        else
            rust_version=$(rustc --version 2>/dev/null)
        fi
        
        if [ -n "$rust_version" ]; then
            complete_progress_success
            success_msg "Rust installed successfully"
            info_msg "Version: $rust_version"
            
            # Get Cargo version
            if [ "$SUDO_USER" ]; then
                cargo_version=$(su - "$SUDO_USER" -c "cargo --version" 2>/dev/null)
            else
                cargo_version=$(cargo --version 2>/dev/null)
            fi
            
            if [ -n "$cargo_version" ]; then
                info_msg "Cargo version: $cargo_version"
            fi
            
            echo ""
            echo "To start using Rust in this terminal, run:"
            echo "  source \"$user_home/.cargo/env\""
            echo ""
            echo "Or simply close and reopen your terminal."
        else
            complete_progress_failure
            error_msg "Failed to install Rust"
            exit 1
        fi
    else
        complete_progress_failure
        error_msg "Failed to install Rust"
        exit 1
    fi
}

# Run the main function
install_rust
