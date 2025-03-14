#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"

# Function: Install Golang
install_golang() {
    show_brand
    section_header "Golang Installation"
    
    # Check if root
    check_root
    
    # Check internet connection
    if ! check_internet; then
        exit 1
    fi
    
    # Check if Golang is already installed
    if command_exists go; then
        current_version=$(go version | awk '{print $3}' | sed 's/go//')
        info_msg "Golang is already installed"
        info_msg "Current version: $current_version"
        
        read -p "Do you want to reinstall or update Golang? (y/n): " choice
        if [[ ! $choice =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    # Ask for desired version
    read -p "Enter Golang version to install (e.g., 1.21.0, 'latest' for latest version): " version
    version=${version:-latest}
    
    # If latest, get the latest version
    if [ "$version" = "latest" ]; then
        info_msg "Fetching latest Golang version..."
        latest_version=$(curl -s https://golang.org/dl/?mode=json | grep -o '"version": "go[0-9.]*"' | head -1 | cut -d '"' -f 4 | sed 's/go//')
        
        if [ -z "$latest_version" ]; then
            error_msg "Failed to fetch latest version. Please check your internet connection."
            exit 1
        fi
        
        version=$latest_version
        info_msg "Latest version: $version"
    fi
    
    # Detect architecture
    arch=$(uname -m)
    case "$arch" in
        x86_64)
            go_arch="amd64"
            ;;
        aarch64|arm64)
            go_arch="arm64"
            ;;
        armv*)
            go_arch="armv6l"
            ;;
        i*86)
            go_arch="386"
            ;;
        *)
            error_msg "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
    
    # Detect OS
    os_type=$(uname -s | tr '[:upper:]' '[:lower:]')
    if [ "$os_type" = "darwin" ]; then
        os_type="darwin"
    elif [ "$os_type" = "linux" ]; then
        os_type="linux"
    else
        error_msg "Unsupported OS: $os_type"
        exit 1
    fi
    
    # Download URL
    download_url="https://golang.org/dl/go${version}.${os_type}-${go_arch}.tar.gz"
    
    # Installation directory
    install_dir="/usr/local"
    
    # Download and install
    info_msg "Downloading Golang $version for $os_type-$go_arch..."
    
    # Create temp directory
    tmp_dir=$(mktemp -d)
    
    # Download Golang
    show_progress "Downloading Golang"
    if ! curl -L -s "$download_url" -o "$tmp_dir/go.tar.gz"; then
        complete_progress_failure
        error_msg "Failed to download Golang. Please check the version number and your internet connection."
        rm -rf "$tmp_dir"
        exit 1
    fi
    complete_progress_success
    
    # Remove any existing Golang installation
    show_progress "Removing existing Golang installation"
    if [ -d "$install_dir/go" ]; then
        rm -rf "$install_dir/go"
    fi
    complete_progress_success
    
    # Extract archive
    show_progress "Extracting Golang"
    if ! tar -C "$install_dir" -xzf "$tmp_dir/go.tar.gz"; then
        complete_progress_failure
        error_msg "Failed to extract Golang"
        rm -rf "$tmp_dir"
        exit 1
    fi
    complete_progress_success
    
    # Clean up
    rm -rf "$tmp_dir"
    
    # Set up environment variables for the current user
    if [ "$SUDO_USER" ]; then
        user_home=$(eval echo ~"$SUDO_USER")
    else
        user_home=$HOME
    fi
    
    # Target profile files
    profile_files=("$user_home/.profile" "$user_home/.bashrc" "$user_home/.zshrc")
    path_line='export PATH=$PATH:/usr/local/go/bin'
    gopath_line='export GOPATH=$HOME/go'
    gobin_line='export PATH=$PATH:$GOPATH/bin'
    
    info_msg "Setting up environment variables..."
    for profile in "${profile_files[@]}"; do
        if [ -f "$profile" ]; then
            # Remove existing Go path entries
            sed -i.bak '/^export PATH=.*\/go\/bin/d' "$profile"
            sed -i.bak '/^export GOPATH=/d' "$profile"
            
            # Add new entries
            echo "$path_line" >> "$profile"
            echo "$gopath_line" >> "$profile"
            echo "$gobin_line" >> "$profile"
            
            # Set proper ownership
            if [ "$SUDO_USER" ]; then
                chown "$SUDO_USER":"$SUDO_USER" "$profile"
            fi
            
            info_msg "Updated $profile"
        fi
    done
    
    # Create Go workspace directory if it doesn't exist
    go_workspace="$user_home/go"
    if [ ! -d "$go_workspace" ]; then
        mkdir -p "$go_workspace"
        if [ "$SUDO_USER" ]; then
            chown -R "$SUDO_USER":"$SUDO_USER" "$go_workspace"
        fi
        info_msg "Created Go workspace at $go_workspace"
    fi
    
    # Verify installation
    export PATH=$PATH:/usr/local/go/bin
    if command_exists go; then
        installed_version=$(go version | awk '{print $3}' | sed 's/go//')
        success_msg "Golang $installed_version installed successfully!"
        echo "To use go commands, either restart your terminal"
        echo "or run the following command to update your current session:"
        echo ""
        echo "  export PATH=\$PATH:/usr/local/go/bin"
        echo "  export GOPATH=\$HOME/go"
        echo "  export PATH=\$PATH:\$GOPATH/bin"
    else
        error_msg "Failed to install Golang"
        exit 1
    fi
}

# Run the main function
install_golang
