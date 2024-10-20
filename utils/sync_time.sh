#!/bin/bash

# Color definitions
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

# Function: Validate region code
validate_region() {
    if [[ ! $1 =~ ^[a-z]{2}$ ]]; then
        echo "Invalid region code. Please enter a two-letter region code (e.g., 'hk')."
        return 1
    fi
    return 0
}

# Function: Update NTP servers
update_ntp_servers() {
    local region_code=$1
    local timesyncd_conf="/etc/systemd/timesyncd.conf"

    # Backup existing configuration
    sudo cp $timesyncd_conf ${timesyncd_conf}.backup

    # Generate NTP server list based on region
    NTP_SERVERS=(
        "${region_code}.pool.ntp.org"
        "0.${region_code}.pool.ntp.org"
        "1.${region_code}.pool.ntp.org"
        "2.${region_code}.pool.ntp.org"
    )

    # Update timesyncd.conf
    sudo sed -i "/^NTP=/d" $timesyncd_conf
    sudo sed -i "/^FallbackNTP=/d" $timesyncd_conf
    echo "NTP=${NTP_SERVERS[*]}" | sudo tee -a $timesyncd_conf > /dev/null

    # Restart systemd-timesyncd service
    sudo systemctl restart systemd-timesyncd

    echo "NTP servers updated successfully."
}

# Main script
show_brand

echo "This script will synchronize your system clock using systemd-timesyncd."
read -p "Please enter your two-letter region code (e.g., 'hk' for Hong Kong): " region_code

# Validate user input
if ! validate_region $region_code; then
    exit 1
fi

echo "The following NTP servers will be configured:"
echo "${region_code}.pool.ntp.org"
echo "0.${region_code}.pool.ntp.org"
echo "1.${region_code}.pool.ntp.org"
echo "2.${region_code}.pool.ntp.org"

read -p "Do you want to proceed? (y/n): " confirm

if [[ $confirm =~ ^[Yy]$ ]]; then
    update_ntp_servers $region_code
else
    echo "Operation cancelled."
    exit 1
fi

echo "System clock synchronization setup is complete."
