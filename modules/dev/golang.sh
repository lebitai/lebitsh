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
    
    # Automatically fetch the latest version
    info_msg "Fetching latest Golang version from go.dev..."
    
    # Use go.dev/dl/?mode=json API to get latest stable version
    latest_version=$(curl -s https://go.dev/dl/?mode=json | jq -r '.[0].version' 2>/dev/null | sed 's/go//')
    
    # Fallback method if jq is not available
    if [ -z "$latest_version" ]; then
        latest_version=$(curl -s https://go.dev/dl/?mode=json | grep -o '"version":"go[0-9.]*"' | head -1 | cut -d '"' -f 4 | sed 's/go//')
    fi
    
    if [ -z "$latest_version" ]; then
        error_msg "Failed to fetch latest version. Please check your internet connection."
        exit 1
    fi
    
    version=$latest_version
    success_msg "Latest stable version: $version"
    
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
    download_url="https://go.dev/dl/go${version}.${os_type}-${go_arch}.tar.gz"
    
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
        user_name="$SUDO_USER"
    else
        user_home=$HOME
        user_name=$(whoami)
    fi
    
    # Define Go environment variables
    path_line='export PATH=$PATH:/usr/local/go/bin'
    gopath_line='export GOPATH=$HOME/go'
    gobin_line='export PATH=$PATH:$GOPATH/bin'
    
    info_msg "Setting up environment variables..."
    
    # Function to add Go paths to a file
    add_go_paths() {
        local file=$1
        
        # Create backup
        cp "$file" "${file}.bak.$(date +%Y%m%d%H%M%S)"
        
        # Remove existing Go path entries (more comprehensive)
        sed -i.tmp -e '/^export PATH=.*\/go\/bin/d' \
                   -e '/^export GOPATH=/d' \
                   -e '/# Go environment/d' \
                   -e '/# Added by lebit.sh/d' "$file"
        rm -f "${file}.tmp"
        
        # Add new entries with comments
        {
            echo ""
            echo "# Go environment - Added by lebit.sh on $(date)"
            echo "$path_line"
            echo "$gopath_line"
            echo "$gobin_line"
        } >> "$file"
    }
    
    # Detect all shell configuration files
    shell_configs=()
    
    # Common shell files
    [ -f "$user_home/.bashrc" ] && shell_configs+=("$user_home/.bashrc")
    [ -f "$user_home/.bash_profile" ] && shell_configs+=("$user_home/.bash_profile")
    [ -f "$user_home/.zshrc" ] && shell_configs+=("$user_home/.zshrc")
    [ -f "$user_home/.profile" ] && shell_configs+=("$user_home/.profile")
    
    # For system-wide configuration
    if [ -d "/etc/profile.d" ] && [ -w "/etc/profile.d" ]; then
        # Create system-wide Go configuration
        cat > /etc/profile.d/golang.sh << EOF
# Go environment - Added by lebit.sh
export PATH=\$PATH:/usr/local/go/bin
export GOPATH=\$HOME/go
export PATH=\$PATH:\$GOPATH/bin
EOF
        chmod 644 /etc/profile.d/golang.sh
        info_msg "Created system-wide configuration at /etc/profile.d/golang.sh"
    fi
    
    # Update user-specific files
    for config in "${shell_configs[@]}"; do
        add_go_paths "$config"
        
        # Set proper ownership
        if [ "$SUDO_USER" ]; then
            chown "$SUDO_USER":"$SUDO_USER" "$config"
        fi
        
        info_msg "Updated $config"
    done
    
    # Also update /etc/environment for Ubuntu/Debian systems
    if [ -f "/etc/environment" ]; then
        # Read current PATH from /etc/environment
        current_path=$(grep "^PATH=" /etc/environment | cut -d'"' -f2)
        if [ -n "$current_path" ] && [[ ! "$current_path" =~ :/usr/local/go/bin ]]; then
            # Update PATH in /etc/environment
            sed -i.bak "s|^PATH=\".*\"|PATH=\"$current_path:/usr/local/go/bin\"|" /etc/environment
            info_msg "Updated /etc/environment"
        fi
    fi
    
    # Create Go workspace directory if it doesn't exist
    go_workspace="$user_home/go"
    if [ ! -d "$go_workspace" ]; then
        mkdir -p "$go_workspace"
        if [ "$SUDO_USER" ]; then
            chown -R "$SUDO_USER":"$SUDO_USER" "$go_workspace"
        fi
        info_msg "Created Go workspace at $go_workspace"
    fi
    
    # Apply environment variables to current session
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$user_home/go
    export PATH=$PATH:$GOPATH/bin
    
    # Verify installation
    if command_exists go; then
        installed_version=$(go version | awk '{print $3}' | sed 's/go//')
        success_msg "Golang $installed_version installed successfully!"
        success_msg "Environment variables have been configured for all shells"
        
        # Create a temporary script for the user to source
        temp_script="/tmp/golang_env_${user_name}.sh"
        cat > "$temp_script" << EOF
#!/bin/bash
# Temporary Go environment setup
export PATH=\$PATH:/usr/local/go/bin
export GOPATH=\$HOME/go
export PATH=\$PATH:\$GOPATH/bin
EOF
        
        if [ "$SUDO_USER" ]; then
            chown "$SUDO_USER":"$SUDO_USER" "$temp_script"
        fi
        
        echo ""
        info_msg "Go is ready to use!"
        info_msg "The PATH has been updated for future sessions."
        info_msg "To use Go in the current session, run:"
        echo "  source $temp_script"
        echo ""
        info_msg "Test your installation with: go version"
    else
        error_msg "Failed to install Golang"
        exit 1
    fi
}

# Run the main function
install_golang
