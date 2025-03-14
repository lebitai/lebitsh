#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common UI functions if not already sourced
if [[ -z "$UI_SOURCED" ]]; then
    source "${SCRIPT_DIR}/ui.sh"
fi

# Set default log level and log file
LOG_LEVEL=${LOG_LEVEL:-"INFO"}
LOG_FILE=${LOG_FILE:-"/tmp/lebitsh.log"}
LOG_TO_CONSOLE=${LOG_TO_CONSOLE:-1}
LOG_ENABLED=${LOG_ENABLED:-1}

# Define log levels
declare -A LOG_LEVELS=(
    ["DEBUG"]=0
    ["INFO"]=1
    ["WARN"]=2
    ["ERROR"]=3
    ["CRITICAL"]=4
)

# Initialize the log file
init_logging() {
    local log_dir=$(dirname "$LOG_FILE")
    
    # Create log directory if it doesn't exist
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" 2>/dev/null
        if [[ $? -ne 0 ]]; then
            echo "Failed to create log directory: $log_dir"
            echo "Logs will only be shown in console"
            LOG_ENABLED=0
        fi
    fi
    
    # Create or truncate the log file
    if [[ $LOG_ENABLED -eq 1 ]]; then
        : > "$LOG_FILE" 2>/dev/null
        if [[ $? -ne 0 ]]; then
            echo "Failed to create log file: $LOG_FILE"
            echo "Logs will only be shown in console"
            LOG_ENABLED=0
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] Logging initialized" >> "$LOG_FILE"
        fi
    fi
}

# Log a message with a specific level
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] [$level] $message"
    
    # Check if the level is valid
    if [[ -z "${LOG_LEVELS[$level]}" ]]; then
        level="INFO"
    fi
    
    # Only log if the level is greater than or equal to the set level
    if [[ ${LOG_LEVELS[$level]} -ge ${LOG_LEVELS[$LOG_LEVEL]} ]]; then
        # Write to log file
        if [[ $LOG_ENABLED -eq 1 ]]; then
            echo "$log_entry" >> "$LOG_FILE"
        fi
        
        # Write to console if enabled
        if [[ $LOG_TO_CONSOLE -eq 1 ]]; then
            case $level in
                "DEBUG")
                    debug_msg "$message"
                    ;;
                "INFO")
                    info_msg "$message"
                    ;;
                "WARN")
                    warning_msg "$message"
                    ;;
                "ERROR")
                    error_msg "$message"
                    ;;
                "CRITICAL")
                    error_msg "CRITICAL: $message"
                    ;;
            esac
        fi
    fi
}

# Convenience functions
log_debug() {
    log_message "DEBUG" "$1"
}

log_info() {
    log_message "INFO" "$1"
}

log_warn() {
    log_message "WARN" "$1"
}

log_error() {
    log_message "ERROR" "$1"
}

log_critical() {
    log_message "CRITICAL" "$1"
}

# Set the log level
set_log_level() {
    local level=$1
    
    if [[ -n "${LOG_LEVELS[$level]}" ]]; then
        LOG_LEVEL=$level
        log_info "Log level set to $LOG_LEVEL"
        return 0
    else
        log_error "Invalid log level: $level"
        log_info "Valid levels: ${!LOG_LEVELS[*]}"
        return 1
    fi
}

# Display logs
show_logs() {
    local lines=${1:-50}
    
    if [[ $LOG_ENABLED -eq 1 && -f "$LOG_FILE" ]]; then
        section_header "Last $lines Log Entries"
        tail -n $lines "$LOG_FILE" | while read -r line; do
            # Extract the level from the log entry
            local level=$(echo "$line" | grep -oP '\[\K[^\]]+' | tail -n 1)
            
            case $level in
                "DEBUG")
                    echo -e "${MAGENTA}$line${NC}"
                    ;;
                "INFO")
                    echo -e "${BLUE}$line${NC}"
                    ;;
                "WARN")
                    echo -e "${YELLOW}$line${NC}"
                    ;;
                "ERROR")
                    echo -e "${RED}$line${NC}"
                    ;;
                "CRITICAL")
                    echo -e "${RED}${BOLD}$line${NC}"
                    ;;
                *)
                    echo "$line"
                    ;;
            esac
        done
    else
        error_msg "No log file available or logging is disabled"
    fi
}

# Clear logs
clear_logs() {
    if [[ $LOG_ENABLED -eq 1 ]]; then
        : > "$LOG_FILE" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            success_msg "Logs cleared"
            init_logging
        else
            error_msg "Failed to clear logs"
        fi
    else
        error_msg "Logging is disabled"
    fi
}

# Initialize logging
init_logging

# Mark as sourced
LOGGING_SOURCED=1

# Log start message
log_info "Logging module loaded"
