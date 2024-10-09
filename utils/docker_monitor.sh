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

# Function: Check if the script is running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root."
    fi
}

# Function: Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        error_exit "Docker is not installed. Please install Docker first."
    fi
}

# Function: Monitor Docker container
monitor_docker() {
    check_docker

    # List all containers
    echo "Current container list:"
    docker ps -a

    # Prompt user for container name and interval
    read -p "Enter the container name to monitor: " CONTAINER_NAME
    read -p "Enter the monitoring interval (minutes): " INTERVAL

    # Generate script file name and log file name
    SCRIPT_FILE="monitor_${CONTAINER_NAME}_docker.sh"
    LOG_FILE="monitor_${CONTAINER_NAME}_docker.log"

    # Prompt user for log file location
    echo "Monitoring log will be saved to: $LOG_FILE"

    # Script content
    cat << EOF > "$SCRIPT_FILE"
#!/bin/bash

# Get the running status of the container
CONTAINER_STATUS=\$(docker inspect --format='{{.State.Status}}' $CONTAINER_NAME)

# Get the current time
CURRENT_TIME=\$(date +"%Y-%m-%d %H:%M:%S")

# Output the check result to the log file
echo "\$CURRENT_TIME - Container $CONTAINER_NAME status: \$CONTAINER_STATUS" >> "$LOG_FILE"

# Take action based on the container's running status
if [[ "\$CONTAINER_STATUS" != "running" ]]; then
  echo "\$CURRENT_TIME - Container $CONTAINER_NAME status is \$CONTAINER_STATUS, attempting to restart..." >> "$LOG_FILE"
  docker start $CONTAINER_NAME
fi
EOF

    # Grant execute permission to the script
    chmod +x "$PWD/$SCRIPT_FILE"

    # Define the new cron job
    NEW_CRON_JOB="*/$INTERVAL * * * * bash $PWD/$SCRIPT_FILE"

    # Check if crontab already contains this job
    crontab -l | grep -Fq "$NEW_CRON_JOB"

    if [ $? -eq 0 ]; then
        echo "\$CURRENT_TIME - Scheduled task already exists, no need to re-add."
    else
        # If the task does not exist, add it to crontab
        (crontab -l 2>/dev/null; echo "$NEW_CRON_JOB") | crontab -
        echo "\$CURRENT_TIME - Container ${CONTAINER_NAME} monitoring task added successfully." >> "$LOG_FILE" 
    fi

    # Execute the script once
    bash "$SCRIPT_FILE"

    echo "Monitoring has started. Please check the log file $LOG_FILE for details."

    read -p "Would you like to view the log file now? (y/n): " VIEW_LOG
    if [[ "$VIEW_LOG" == "y" ]]; then
        cat "$LOG_FILE"
        exit 0
    else
        exit 0
    fi
}

# Function: Exit the script
exit_shell() {
    clear
    exit 0
}

# Main function
main() {
    show_brand
    echo "Welcome to use this script to monitor Docker containers."
    echo "================================================================"
    echo "Please select the operation to be performed:"
    echo "1. Install monitoring scripts"
    echo "2. Exit"
    read -p "Please enter an option (1-2): " OPTION

    case $OPTION in
    1) monitor_docker;;
    2) exit_shell;;
    *) echo -e "${RED}Invalid option, please try again.${NC}";;
    esac
}

main
