/**
 * Welcome to Cloudflare Workers! This is your first worker.
 *
 * - Run `wrangler dev` in your terminal to start a development server
 * - Open a browser tab at http://localhost:8787/ to see your worker in action
 * - Run `wrangler deploy` to publish your worker
 *
 * Learn more at https://developers.cloudflare.com/workers/
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    
    // For the root path, serve the install script
    if (path === '/') {
      // Read the install.sh file from assets
      try {
        const installScriptResponse = await env.ASSETS.fetch(new URL('/install.sh', url));
        const installScript = await installScriptResponse.text();
        
        return new Response(installScript, {
          headers: {
            'Content-Type': 'application/x-sh',
            'Content-Disposition': 'attachment; filename="install.sh"'
          }
        });
      } catch (e) {
        // Fallback if install.sh is not found
        const installScript = `#!/bin/bash

# Lebit.sh Installation Script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
info() {
    echo -e "\${BLUE}[INFO]\${NC} \$1"
}

success() {
    echo -e "\${GREEN}[SUCCESS]\${NC} \$1"
}

warning() {
    echo -e "\${YELLOW}[WARNING]\${NC} \$1"
}

error() {
    echo -e "\${RED}[ERROR]\${NC} \$1"
}

# Function to check if running as root
check_root() {
    if [ "\$EUID" -eq 0 ]; then
        error "This script should not be run as root. Please run without sudo."
        exit 1
    fi
}

# Function to detect OS
detect_os() {
    if [[ "\$(uname)" != "Linux" ]]; then
        error "This script is designed for Linux systems only"
        exit 1
    fi

    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        DISTRO=\$ID
        VERSION=\$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        DISTRO=\$(lsb_release -si)
        VERSION=\$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # shellcheck disable=SC1091
        source /etc/lsb-release
        DISTRO=\$DISTRIB_ID
        VERSION=\$DISTRIB_RELEASE
    else
        error "Unsupported Linux distribution"
        exit 1
    fi

    # Convert to lowercase
    DISTRO=\$(echo "\$DISTRO" | tr '[:upper:]' '[:lower:]')
    info "Detected OS: \$DISTRO:\$VERSION"
}

# Function to check if command exists
command_exists() {
    command -v "\$1" >/dev/null 2>&1
}

# Function to check internet connection
check_internet() {
    info "Checking internet connection..."
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        success "Internet connection is available"
    else
        error "No internet connection detected"
        exit 1
    fi
}

# Function to install required packages
install_packages() {
    info "Installing required packages..."
    
    case \$DISTRO in
        ubuntu|debian)
            sudo apt-get update -qq >/dev/null
            sudo apt-get install -y curl sudo >/dev/null 2>&1
            ;;
        centos|rhel|fedora|rocky|almalinux)
            if command_exists dnf; then
                sudo dnf install -y curl sudo >/dev/null 2>&1
            else
                sudo yum install -y curl sudo >/dev/null 2>&1
            fi
            ;;
        *)
            error "Unsupported distribution: \$DISTRO"
            exit 1
            ;;
    esac
    
    success "Required packages installed"
}

# Function to download and run the main installer
install_lebitsh() {
    info "Downloading Lebit.sh..."
    
    # Create temporary directory
    TEMP_DIR=\$(mktemp -d)
    cd "\$TEMP_DIR"
    
    # Download the main script
    if ! curl -fsSL "https://raw.githubusercontent.com/lebitai/lebitsh/main/main.sh" -o main.sh; then
        error "Failed to download main installer"
        cleanup
        exit 1
    fi
    
    # Make it executable
    chmod +x main.sh
    
    success "Download completed"
    
    # Run the main installer
    info "Running Lebit.sh installer..."
    bash main.sh "\$@"
    
    # Cleanup
    cleanup
}

# Function to cleanup temporary files
cleanup() {
    if [ -d "\$TEMP_DIR" ]; then
        rm -rf "\$TEMP_DIR"
    fi
}

# Main function
main() {
    # Check if we're running as root
    check_root
    
    # Detect OS
    detect_os
    
    # Check internet connection
    check_internet
    
    # Install required packages
    install_packages
    
    # Install Lebit.sh
    install_lebitsh "\$@"
    
    success "Lebit.sh installation completed!"
    echo "You can now run 'lebitsh' to start the toolkit."
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Run main function with all arguments
main "\$@"
`;
        
        return new Response(installScript, {
          headers: {
            'Content-Type': 'application/x-sh',
            'Content-Disposition': 'attachment; filename="install.sh"'
          }
        });
      }
    }
    
    // For other paths, serve static assets
    return env.ASSETS.fetch(request);
  },
};