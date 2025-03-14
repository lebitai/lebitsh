#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source UI and logging functions if not already sourced
if [[ -z "$UI_SOURCED" ]]; then
    source "${SCRIPT_DIR}/ui.sh"
fi

if [[ -z "$LOGGING_SOURCED" ]]; then
    source "${SCRIPT_DIR}/logging.sh"
fi

# Define default configuration locations
USER_CONFIG_DIR="${HOME}/.config/lebitsh"
SYSTEM_CONFIG_DIR="/etc/lebitsh"
DEFAULT_CONFIG_FILE="${SCRIPT_DIR}/../config/defaults.conf"
USER_CONFIG_FILE="${USER_CONFIG_DIR}/config.conf"
SYSTEM_CONFIG_FILE="${SYSTEM_CONFIG_DIR}/config.conf"

# Default configuration values
declare -A CONFIG=(
    ["log_level"]="INFO"
    ["log_file"]="/tmp/lebitsh.log"
    ["auto_update"]="false"
    ["update_check_interval"]="7"  # days
    ["use_colors"]="true"
    ["show_system_info"]="true"
    ["temp_dir"]="/tmp/lebitsh"
    ["backup_dir"]="${HOME}/.lebitsh/backups"
    ["download_timeout"]="60"
    ["docker_registry"]="docker.io"
    ["ntp_server"]="pool.ntp.org"
    ["default_editor"]="vi"
)

# Function to load configuration from a file
load_config_file() {
    local config_file="$1"
    
    if [[ -f "$config_file" ]]; then
        log_debug "Loading configuration from $config_file"
        
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^[[:space:]]*# ]] || [[ -z "$key" ]] && continue
            
            # Trim whitespace
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            
            # Update configuration if key exists
            if [[ -n "${CONFIG[$key]}" ]]; then
                CONFIG["$key"]="$value"
                log_debug "Set $key = $value"
            fi
        done < "$config_file"
        
        return 0
    else
        log_debug "Configuration file not found: $config_file"
        return 1
    fi
}

# Function to create default configuration
create_default_config() {
    local config_dir="$1"
    local config_file="$2"
    
    # Create directory if it doesn't exist
    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir" 2>/dev/null
        if [[ $? -ne 0 ]]; then
            log_error "Failed to create config directory: $config_dir"
            return 1
        fi
    fi
    
    # Create configuration file if it doesn't exist
    if [[ ! -f "$config_file" ]]; then
        log_info "Creating default configuration in $config_file"
        
        # Write header
        echo "# Lebit.sh Configuration File" > "$config_file"
        echo "# Generated on $(date)" >> "$config_file"
        echo "" >> "$config_file"
        
        # Write default values with descriptions
        echo "# Logging level (DEBUG, INFO, WARN, ERROR, CRITICAL)" >> "$config_file"
        echo "log_level=${CONFIG[log_level]}" >> "$config_file"
        echo "" >> "$config_file"
        
        echo "# Log file location" >> "$config_file"
        echo "log_file=${CONFIG[log_file]}" >> "$config_file"
        echo "" >> "$config_file"
        
        echo "# Enable automatic updates (true/false)" >> "$config_file"
        echo "auto_update=${CONFIG[auto_update]}" >> "$config_file"
        echo "" >> "$config_file"
        
        echo "# Days between update checks" >> "$config_file"
        echo "update_check_interval=${CONFIG[update_check_interval]}" >> "$config_file"
        echo "" >> "$config_file"
        
        echo "# Use colored output (true/false)" >> "$config_file"
        echo "use_colors=${CONFIG[use_colors]}" >> "$config_file"
        echo "" >> "$config_file"
        
        echo "# Show system information on startup (true/false)" >> "$config_file"
        echo "show_system_info=${CONFIG[show_system_info]}" >> "$config_file"
        echo "" >> "$config_file"
        
        echo "# Temporary directory for downloads and operations" >> "$config_file"
        echo "temp_dir=${CONFIG[temp_dir]}" >> "$config_file"
        echo "" >> "$config_file"
        
        echo "# Directory for backups" >> "$config_file"
        echo "backup_dir=${CONFIG[backup_dir]}" >> "$config_file"
        echo "" >> "$config_file"
        
        echo "# Download timeout in seconds" >> "$config_file"
        echo "download_timeout=${CONFIG[download_timeout]}" >> "$config_file"
        echo "" >> "$config_file"
        
        echo "# Docker registry to use" >> "$config_file"
        echo "docker_registry=${CONFIG[docker_registry]}" >> "$config_file"
        echo "" >> "$config_file"
        
        echo "# NTP server for time synchronization" >> "$config_file"
        echo "ntp_server=${CONFIG[ntp_server]}" >> "$config_file"
        echo "" >> "$config_file"
        
        echo "# Default text editor" >> "$config_file"
        echo "default_editor=${CONFIG[default_editor]}" >> "$config_file"
        
        return 0
    else
        log_debug "Configuration file already exists: $config_file"
        return 0
    fi
}

# Function to get a configuration value
get_config() {
    local key="$1"
    local default_value="$2"
    
    # If key exists in CONFIG, return its value
    if [[ -n "${CONFIG[$key]}" ]]; then
        echo "${CONFIG[$key]}"
    else
        # Otherwise, return the default value if provided
        if [[ -n "$default_value" ]]; then
            echo "$default_value"
        else
            log_error "Configuration key not found: $key"
            return 1
        fi
    fi
}

# Function to set a configuration value
set_config() {
    local key="$1"
    local value="$2"
    local config_file="${USER_CONFIG_FILE}"
    
    # Check if key exists in CONFIG
    if [[ -n "${CONFIG[$key]}" ]]; then
        # Update in-memory configuration
        CONFIG["$key"]="$value"
        
        # Check if user config file exists, create if not
        if [[ ! -f "$config_file" ]]; then
            create_default_config "${USER_CONFIG_DIR}" "$config_file"
        fi
        
        # Check if key already exists in file
        if grep -q "^${key}=" "$config_file"; then
            # Update existing key
            sed -i "s/^${key}=.*/${key}=${value}/" "$config_file"
        else
            # Add new key
            echo "${key}=${value}" >> "$config_file"
        fi
        
        log_info "Configuration updated: $key = $value"
        return 0
    else
        log_error "Invalid configuration key: $key"
        return 1
    fi
}

# Function to show current configuration
show_config() {
    section_header "Current Configuration"
    
    # Calculate the longest key for formatting
    local max_key_length=0
    for key in "${!CONFIG[@]}"; do
        if [[ ${#key} -gt $max_key_length ]]; then
            max_key_length=${#key}
        fi
    done
    
    # Sort keys alphabetically and display
    for key in $(echo "${!CONFIG[@]}" | tr ' ' '\n' | sort); do
        printf "  ${BOLD}%-${max_key_length}s${NC} = %s\n" "$key" "${CONFIG[$key]}"
    done
    
    echo
    info_msg "Configuration files:"
    if [[ -f "$USER_CONFIG_FILE" ]]; then
        echo "  - User config: $USER_CONFIG_FILE"
    fi
    
    if [[ -f "$SYSTEM_CONFIG_FILE" ]]; then
        echo "  - System config: $SYSTEM_CONFIG_FILE"
    fi
    
    if [[ -f "$DEFAULT_CONFIG_FILE" ]]; then
        echo "  - Default config: $DEFAULT_CONFIG_FILE"
    fi
    
    echo
}

# Function to edit configuration
edit_config() {
    local config_file="${USER_CONFIG_FILE}"
    local editor
    
    # Check if user config file exists, create if not
    if [[ ! -f "$config_file" ]]; then
        create_default_config "${USER_CONFIG_DIR}" "$config_file"
    fi
    
    # Get editor from configuration or environment
    editor=$(get_config "default_editor" "${EDITOR:-vi}")
    
    # Open the configuration file in the editor
    $editor "$config_file"
    
    # Reload configuration
    load_config
    
    log_info "Configuration reloaded"
    return 0
}

# Function to reset configuration to defaults
reset_config() {
    local config_file="${USER_CONFIG_FILE}"
    
    if [[ -f "$config_file" ]]; then
        if yes_no_prompt "Are you sure you want to reset to default configuration?" "n"; then
            rm -f "$config_file"
            log_info "Configuration reset to defaults"
            
            # Initialize configuration again
            init_config
            return 0
        else
            log_info "Reset cancelled"
            return 1
        fi
    else
        log_info "No user configuration to reset"
        return 0
    fi
}

# Function to load all configuration files
load_config() {
    # Load configuration in order: defaults, system, user
    if [[ -f "$DEFAULT_CONFIG_FILE" ]]; then
        load_config_file "$DEFAULT_CONFIG_FILE"
    fi
    
    if [[ -f "$SYSTEM_CONFIG_FILE" ]]; then
        load_config_file "$SYSTEM_CONFIG_FILE"
    fi
    
    if [[ -f "$USER_CONFIG_FILE" ]]; then
        load_config_file "$USER_CONFIG_FILE"
    fi
    
    # Apply configuration
    apply_config
    
    return 0
}

# Function to apply configuration settings
apply_config() {
    # Set log level from configuration
    if [[ -n "$LOGGING_SOURCED" ]]; then
        set_log_level "${CONFIG[log_level]}"
        LOG_FILE="${CONFIG[log_file]}"
    fi
    
    # Set temporary directory
    LEBITSH_TEMP_DIR="${CONFIG[temp_dir]}"
    
    # Apply color settings
    if [[ "${CONFIG[use_colors]}" != "true" ]]; then
        RED=''
        GREEN=''
        YELLOW=''
        BLUE=''
        CYAN=''
        MAGENTA=''
        WHITE=''
        BOLD=''
        DIM=''
        UNDERLINE=''
        BLINK=''
        NC=''
    fi
    
    return 0
}

# Function to initialize configuration
init_config() {
    # Create default configuration directory and file if not exists
    create_default_config "${USER_CONFIG_DIR}" "${USER_CONFIG_FILE}"
    
    # Load all configuration files
    load_config
    
    # Mark as initialized
    CONFIG_INITIALIZED=1
    
    return 0
}

# Initialize configuration
if [[ -z "$CONFIG_INITIALIZED" ]]; then
    init_config
fi

# Mark as sourced
CONFIG_SOURCED=1

# Log configuration loaded
log_debug "Configuration module loaded"
