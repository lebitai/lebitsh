#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"

# Function: Setup quick aliases
setup_quick_aliases() {
    show_brand
    section_header "Quick Aliases Setup"
    
    # Determine user profile file
    if [ "$SUDO_USER" ]; then
        user_home=$(eval echo ~"$SUDO_USER")
        actual_user="$SUDO_USER"
    else
        user_home="$HOME"
        actual_user="$(whoami)"
    fi
    
    # Detect shell type
    echo -n "Detecting default shell... "
    if [ "$SUDO_USER" ]; then
        user_shell=$(getent passwd "$SUDO_USER" | cut -d: -f7)
    else
        user_shell=$SHELL
    fi
    
    echo "$user_shell"
    
    # Determine profile file based on shell
    case "$user_shell" in
        */bash)
            profile_file="$user_home/.bashrc"
            ;;
        */zsh)
            profile_file="$user_home/.zshrc"
            ;;
        */fish)
            profile_file="$user_home/.config/fish/config.fish"
            # Create directory if it doesn't exist
            if [ ! -d "$(dirname "$profile_file")" ]; then
                mkdir -p "$(dirname "$profile_file")"
            fi
            ;;
        *)
            # Default to .profile for other shells
            profile_file="$user_home/.profile"
            ;;
    esac
    
    info_msg "Will update: $profile_file"
    
    # Create backup of the profile file
    if [ -f "$profile_file" ]; then
        backup_file="${profile_file}.bak.$(date +%Y%m%d%H%M%S)"
        cp "$profile_file" "$backup_file"
        info_msg "Backup created at $backup_file"
    fi
    
    # Prepare aliases based on shell type
    aliases_content=""
    
    # Common aliases for all shells
    common_aliases=$(cat << 'EOF'
# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Enhanced ls commands
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# System information
alias df='df -h'
alias du='du -h'
alias free='free -m'

# Network tools
alias ports='netstat -tulanp'
alias ips='ip -c a'

# Process management
alias psa='ps aux'
alias psg='ps aux | grep -v grep | grep -i'

# File operations
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
alias mkdir='mkdir -p'

# Git shortcuts
alias gs='git status'
alias gl='git log'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gpull='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Docker shortcuts
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dexec='docker exec -it'
alias dlogs='docker logs'

# Quick edit of this file
alias aliases='${EDITOR:-nano} $profile_file'

# Always make scripts executable
alias cx='chmod +x'

# Show open ports
alias openports='sudo lsof -i -P -n | grep LISTEN'

# System updates
EOF
)
    
    # OS-specific aliases
    os_info=$(check_os)
    distro=$(echo "$os_info" | cut -d':' -f1)
    
    case $distro in
        ubuntu|debian)
            os_aliases=$(cat << 'EOF'
# System updates for Ubuntu/Debian
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install'
alias remove='sudo apt remove'
alias autoremove='sudo apt autoremove'
EOF
)
            ;;
        centos|rhel|fedora|rocky|almalinux)
            if command_exists dnf; then
                os_aliases=$(cat << 'EOF'
# System updates for CentOS/RHEL/Fedora with dnf
alias update='sudo dnf update -y'
alias install='sudo dnf install'
alias remove='sudo dnf remove'
alias autoremove='sudo dnf autoremove'
EOF
)
            else
                os_aliases=$(cat << 'EOF'
# System updates for CentOS/RHEL with yum
alias update='sudo yum update -y'
alias install='sudo yum install'
alias remove='sudo yum remove'
alias autoremove='sudo yum autoremove'
EOF
)
            fi
            ;;
        *)
            os_aliases=""
            ;;
    esac
    
    # Combine all aliases
    aliases_content="$common_aliases
$os_aliases"
    
    # Format aliases for the specific shell
    case "$user_shell" in
        */fish)
            # Convert aliases to fish function format
            aliases_content=$(echo "$aliases_content" | grep -v '^#' | sed '/^$/d' | sed 's/alias \([^=]*\)=\(.*\)/function \1\n    \2\nend/')
            ;;
        *)
            # Bash/Zsh/others use the standard alias format, no changes needed
            ;;
    esac
    
    # Show aliases that will be added
    section_header "Aliases to be added"
    echo "$aliases_content"
    echo ""
    
    # Confirm with user
    read -p "Do you want to add these aliases to $profile_file? (y/n): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        info_msg "Operation cancelled"
        exit 0
    fi
    
    # Add aliases to profile file
    show_progress "Adding aliases to $profile_file"
    
    # Check if we already have a aliases section
    if grep -q "# Lebit.sh Quick Aliases" "$profile_file"; then
        # Replace existing aliases section
        if [ "$user_shell" = "*/fish" ]; then
            sed -i '/# Lebit.sh Quick Aliases/,/# End of Lebit.sh Quick Aliases/d' "$profile_file"
        else
            sed -i '/# Lebit.sh Quick Aliases/,/# End of Lebit.sh Quick Aliases/d' "$profile_file"
        fi
    fi
    
    # Add new aliases section
    cat << EOF >> "$profile_file"
# Lebit.sh Quick Aliases
# Added on $(date)
$aliases_content
# End of Lebit.sh Quick Aliases
EOF
    
    # Set correct ownership if running as sudo
    if [ "$SUDO_USER" ]; then
        chown "$SUDO_USER":"$SUDO_USER" "$profile_file"
    fi
    
    complete_progress_success
    success_msg "Aliases added successfully to $profile_file"
    
    echo ""
    info_msg "You need to reload your shell configuration to use the new aliases:"
    case "$user_shell" in
        */bash)
            echo "  source $profile_file"
            ;;
        */zsh)
            echo "  source $profile_file"
            ;;
        */fish)
            echo "  source $profile_file"
            ;;
        *)
            echo "  source $profile_file"
            ;;
    esac
    
    echo "  or simply open a new terminal window"
}

# Run the main function
setup_quick_aliases
