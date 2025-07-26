#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"

# Function: Setup Docker container monitoring
setup_docker_monitoring() {
    show_brand
    section_header "Docker Container Monitoring"
    
    # Check if root
    check_root
    
    # Check if Docker is installed
    if ! command_exists docker; then
        error_msg "Docker is not installed. Please install Docker first."
        info_msg "You can install Docker using:"
        echo "  curl --proto '=https' --tlsv1.2 -sSf https://lebit.sh/docker | sh"
        exit 1
    fi
    
    # Get current containers
    info_msg "Current Docker containers:"
    docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
    echo ""
    
    # Prompt for container name
    read -p "Enter the container name to monitor: " container_name
    
    # Verify the container exists
    if ! docker ps -a --format "{{.Names}}" | grep -q "^${container_name}$"; then
        error_msg "Container '$container_name' not found."
        exit 1
    fi
    
    # Prompt for monitoring interval
    read -p "Enter the monitoring interval in minutes [5]: " interval
    interval=${interval:-5}
    
    # Validate interval is a number
    if ! [[ "$interval" =~ ^[0-9]+$ ]]; then
        error_msg "Interval must be a positive number."
        exit 1
    fi
    
    # Generate script and log file names
    script_file="/usr/local/bin/monitor_${container_name}.sh"
    log_file="/var/log/docker_monitor_${container_name}.log"
    
    info_msg "Monitoring script will be created at: $script_file"
    info_msg "Monitoring log will be saved to: $log_file"
    
    # Create the monitoring script
    cat << EOF > "$script_file"
#!/bin/bash

# Docker container monitoring script for $container_name
# Created by Lebit.sh Docker monitoring utility
# $(date)

# Get the running status of the container
CONTAINER_STATUS=\$(docker inspect --format='{{.State.Status}}' $container_name 2>/dev/null)
EXIT_CODE=\$?

# Get the current time
CURRENT_TIME=\$(date +"%Y-%m-%d %H:%M:%S")

# Check if the container exists
if [ \$EXIT_CODE -ne 0 ]; then
    echo "\$CURRENT_TIME - ERROR: Container $container_name not found" >> "$log_file"
    exit 1
fi

# Output the check result to the log file
echo "\$CURRENT_TIME - Container $container_name status: \$CONTAINER_STATUS" >> "$log_file"

# Take action based on the container's running status
if [[ "\$CONTAINER_STATUS" != "running" ]]; then
    echo "\$CURRENT_TIME - Container $container_name is \$CONTAINER_STATUS, attempting to restart..." >> "$log_file"
    docker start $container_name >> "$log_file" 2>&1
    
    # Check if restart was successful
    NEW_STATUS=\$(docker inspect --format='{{.State.Status}}' $container_name 2>/dev/null)
    if [[ "\$NEW_STATUS" == "running" ]]; then
        echo "\$CURRENT_TIME - Container $container_name successfully restarted" >> "$log_file"
    else
        echo "\$CURRENT_TIME - FAILED to restart container $container_name" >> "$log_file"
    fi
fi

# Limit log file size
if [ -f "$log_file" ]; then
    # Keep only the last 1000 lines
    tail -n 1000 "$log_file" > "${log_file}.tmp" && mv "${log_file}.tmp" "$log_file"
fi
EOF
    
    # Make script executable
    chmod +x "$script_file"
    
    # Create log file if it doesn't exist
    touch "$log_file"
    chmod 644 "$log_file"
    
    # Add cron job
    cron_schedule="*/$interval * * * *"
    if add_cron_job "$script_file" "$cron_schedule"; then
        success_msg "Docker monitoring for container '$container_name' has been set up"
        success_msg "Monitoring interval: Every $interval minutes"
    else
        error_msg "Failed to set up cron job"
        exit 1
    fi
    
    # Run the script once
    info_msg "Running initial container check..."
    bash "$script_file"
    
    # Ask if user wants to view the log
    read -p "Do you want to view the monitoring log? (y/n): " view_log
    if [[ $view_log =~ ^[Yy]$ ]]; then
        cat "$log_file"
    fi
    
    # Provide information about log file location
    echo ""
    info_msg "To view the monitoring log at any time, use:"
    echo "  cat $log_file"
}

# Function: List current monitoring configurations
list_monitoring() {
    show_brand
    section_header "Docker Monitoring Configurations"
    
    # Check for monitoring scripts
    if ls /usr/local/bin/monitor_*.sh >/dev/null 2>&1; then
        info_msg "Current monitoring configurations:"
        echo ""
        echo "Container Name | Interval | Status"
        echo "---------------|----------|-------"
        
        for script in /usr/local/bin/monitor_*.sh; do
            container=$(basename "$script" .sh | sed 's/monitor_//')
            
            # Extract interval from crontab
            if crontab -l 2>/dev/null | grep -q "$script"; then
                interval=$(crontab -l | grep "$script" | awk '{print $1}' | sed 's/\*\///' | sed 's/ .*//')
                status="Active"
            else
                interval="N/A"
                status="Inactive"
            fi
            
            echo "$container | $interval min | $status"
        done
    else
        info_msg "No monitoring configurations found."
    fi
}

# Function: Remove monitoring for a container
remove_monitoring() {
    show_brand
    section_header "Remove Docker Monitoring"
    
    # Check if root
    check_root
    
    # Check for monitoring scripts
    if ! ls /usr/local/bin/monitor_*.sh >/dev/null 2>&1; then
        info_msg "No monitoring configurations found."
        exit 0
    fi
    
    # List available monitoring configurations
    info_msg "Current monitoring configurations:"
    echo ""
    
    # Create an array of container names
    containers=()
    for script in /usr/local/bin/monitor_*.sh; do
        container=$(basename "$script" .sh | sed 's/monitor_//')
        containers+=("$container")
        echo "$(echo ${#containers[@]}) $container"
    done
    
    echo "$(echo $((${#containers[@]} + 1))) Exit"
    
    # Prompt for container selection
    read -p "Enter the number of the container to remove monitoring for: " selection
    
    # Validate selection
    if ! [[ "$selection" =~ ^[0-9]+$ ]]; then
        error_msg "Invalid selection."
        exit 1
    fi
    
    if [ "$selection" -eq "$((${#containers[@]} + 1))" ]; then
        # Exit option selected
        exit 0
    elif [ "$selection" -ge 1 ] && [ "$selection" -le "${#containers[@]}" ]; then
        # Valid container selected
        container=${containers[$((selection - 1))]}
        script_file="/usr/local/bin/monitor_${container}.sh"
        log_file="/var/log/docker_monitor_${container}.log"
        
        # Remove from crontab
        show_progress "Removing cron job"
        (crontab -l 2>/dev/null | grep -v "$script_file") | crontab -
        complete_progress_success
        
        # Remove script file
        show_progress "Removing script file"
        rm -f "$script_file"
        complete_progress_success
        
        # Ask about log file
        read -p "Do you want to keep the monitoring log file? (y/n): " keep_log
        if [[ ! $keep_log =~ ^[Yy]$ ]]; then
            show_progress "Removing log file"
            rm -f "$log_file"
            complete_progress_success
        fi
        
        success_msg "Monitoring for container '$container' has been removed"
    else
        error_msg "Invalid selection."
        exit 1
    fi
}

# Main function
main() {
    show_brand
    section_header "Docker Container Monitoring"
    
    # Display menu options
    options=(
        "Set up monitoring for a container"
        "List current monitoring configurations"
        "Remove monitoring for a container"
        "Exit"
    )
    
    show_menu "Select an operation:" "${options[@]}"
    choice=$?
    
    case $choice in
        1)
            # Set up monitoring
            setup_docker_monitoring
            ;;
        2)
            # List monitoring
            list_monitoring
            ;;
        3)
            # Remove monitoring
            remove_monitoring
            ;;
        4)
            # Exit
            exit 0
            ;;
        *)
            # Invalid option
            error_msg "Invalid option"
            exit 1
            ;;
    esac
}

# Run the main function
main
