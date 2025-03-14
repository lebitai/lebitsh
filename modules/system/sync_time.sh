#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"

# Function: Sync system time
do_sync_time() {
    show_brand
    section_header "System Time Synchronization"
    
    # Check if root
    check_root
    
    # Display current system time
    current_time=$(date)
    info_msg "Current system time: $current_time"
    
    # Check internet connection
    if ! check_internet; then
        error_msg "Internet connection is required for time synchronization"
        exit 1
    fi
    
    # Sync time
    if ! sync_system_time; then
        error_msg "Failed to synchronize time"
        exit 1
    fi
    
    # Display new system time
    new_time=$(date)
    success_msg "System time synchronized successfully"
    info_msg "New system time: $new_time"
    
    # Check and configure NTP service for automatic time sync
    configure_ntp_service
}

# Function: Configure NTP service
configure_ntp_service() {
    section_header "NTP Service Configuration"
    
    local os_info
    os_info=$(check_os)
    local distro
    distro=$(echo "$os_info" | cut -d':' -f1)
    
    # Check if chronyd or ntpd is installed and running
    if command_exists systemctl; then
        if systemctl list-unit-files | grep -q chronyd; then
            ntp_service="chronyd"
        elif systemctl list-unit-files | grep -q ntpd; then
            ntp_service="ntpd"
        else
            ntp_service=""
        fi
    fi
    
    if [ -n "$ntp_service" ]; then
        show_progress "Checking NTP service status"
        if systemctl is-active --quiet "$ntp_service"; then
            complete_progress_success
            success_msg "$ntp_service is active and running"
        else
            complete_progress_failure
            warning_msg "$ntp_service is installed but not running"
            
            read -p "Do you want to enable and start $ntp_service? (y/n): " start_service
            if [[ $start_service =~ ^[Yy]$ ]]; then
                show_progress "Starting $ntp_service"
                systemctl enable "$ntp_service" >/dev/null 2>&1
                systemctl start "$ntp_service" >/dev/null 2>&1
                
                if systemctl is-active --quiet "$ntp_service"; then
                    complete_progress_success
                    success_msg "$ntp_service is now active and running"
                else
                    complete_progress_failure
                    error_msg "Failed to start $ntp_service"
                fi
            fi
        fi
    else
        # NTP service not installed, offer to install it
        warning_msg "No NTP service (chronyd or ntpd) found"
        
        read -p "Do you want to install an NTP service for automatic time synchronization? (y/n): " install_ntp
        if [[ $install_ntp =~ ^[Yy]$ ]]; then
            case $distro in
                ubuntu|debian)
                    show_progress "Installing chrony NTP service"
                    apt-get update -qq >/dev/null
                    apt-get install -y chrony >/dev/null 2>&1
                    ;;
                centos|rhel|fedora|rocky|almalinux)
                    show_progress "Installing chrony NTP service"
                    if command_exists dnf; then
                        dnf install -y chrony >/dev/null 2>&1
                    else
                        yum install -y chrony >/dev/null 2>&1
                    fi
                    ;;
                *)
                    complete_progress_failure
                    error_msg "Unsupported distribution for automatic NTP installation"
                    return 1
                    ;;
            esac
            
            if [ $? -eq 0 ]; then
                complete_progress_success
                
                # Start and enable the service
                show_progress "Starting chrony NTP service"
                systemctl enable chronyd >/dev/null 2>&1
                systemctl start chronyd >/dev/null 2>&1
                
                if systemctl is-active --quiet chronyd; then
                    complete_progress_success
                    success_msg "Chrony NTP service is now active and running"
                else
                    complete_progress_failure
                    error_msg "Failed to start chrony NTP service"
                fi
            else
                complete_progress_failure
                error_msg "Failed to install NTP service"
            fi
        fi
    fi
    
    # Offer to set up a cron job for manual time sync
    read -p "Do you want to set up a daily cron job for time synchronization? (y/n): " setup_cron
    if [[ $setup_cron =~ ^[Yy]$ ]]; then
        # Create a simple script for time sync
        local script_path="/usr/local/bin/sync_time.sh"
        
        cat << 'EOF' > "$script_path"
#!/bin/bash
# Sync system time
if command -v ntpdate >/dev/null 2>&1; then
    ntpdate -u pool.ntp.org >/dev/null 2>&1
fi
EOF
        chmod +x "$script_path"
        
        # Add cron job
        if add_cron_job "$script_path" "0 0 * * *"; then
            success_msg "Cron job for daily time synchronization has been set up"
        else
            error_msg "Failed to set up cron job"
        fi
    fi
}

# Run the main function
do_sync_time
