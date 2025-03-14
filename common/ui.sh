#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
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

# Function: Display compact brand (for limited space)
show_compact_brand() {
    echo -e "${WHITE}Lebit.sh${NC} - Linux System Initialization Toolkit"
}

# Function: Display section header
section_header() {
    echo -e "\n${BLUE}${BOLD}==== $1 ====${NC}"
}

# Function: Display subsection header
subsection_header() {
    echo -e "${CYAN}--- $1 ---${NC}"
}

# Function: Display success message
success_msg() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function: Display error message
error_msg() {
    echo -e "${RED}✗ Error: $1${NC}" >&2
}

# Function: Display warning message
warning_msg() {
    echo -e "${YELLOW}⚠ Warning: $1${NC}"
}

# Function: Display info message
info_msg() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Function: Display note message
note_msg() {
    echo -e "${DIM}Note: $1${NC}"
}

# Function: Display debug message (only when DEBUG=1)
debug_msg() {
    if [ "${DEBUG:-0}" = "1" ]; then
        echo -e "${MAGENTA}🐞 Debug: $1${NC}"
    fi
}

# Function: Display a menu and get user selection
show_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=0
    
    section_header "$title"
    
    for i in "${!options[@]}"; do
        echo -e "  ${CYAN}$(($i+1))${NC}. ${options[$i]}"
    done
    
    echo ""
    read -p "Please select an option (1-${#options[@]}): " selected
    
    if [[ "$selected" -ge 1 ]] && [[ "$selected" -le "${#options[@]}" ]]; then
        return $selected
    else
        error_msg "Invalid option"
        return 0
    fi
}

# Function: Display a yes/no prompt and return 0 for yes, 1 for no
yes_no_prompt() {
    local question="$1"
    local default="${2:-y}"
    local response
    
    if [[ "$default" = "y" ]]; then
        read -p "$question [Y/n]: " response
        response=${response:-y}
    else
        read -p "$question [y/N]: " response
        response=${response:-n}
    fi
    
    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function: Display progress
show_progress() {
    local message="$1"
    echo -ne "${YELLOW}$message... ${NC}"
}

# Function: Complete progress with success
complete_progress_success() {
    local message="$1"
    echo -e "${GREEN}Done${NC} $message"
}

# Function: Complete progress with failure
complete_progress_failure() {
    local message="$1"
    echo -e "${RED}Failed${NC} $message"
}

# Function: Display a spinning progress indicator
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    
    while ps -p $pid > /dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function: Display a progress bar
progress_bar() {
    local current=$1
    local total=$2
    local prefix="${3:-Progress:}"
    local suffix="${4:-%}"
    local length=${5:-30}
    
    local filled=$(( current * length / total ))
    local empty=$(( length - filled ))
    
    local progress=$(( 100 * current / total ))
    
    printf "\r${prefix} ["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "] ${progress}${suffix}"
    
    if [ "$current" -ge "$total" ]; then
        echo
    fi
}

# Function: Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function: Display a table
show_table() {
    local title="$1"
    shift
    local headers=("$1")
    shift
    local rows=("$@")
    
    section_header "$title"
    
    # Print the header
    echo -e "${BOLD}${headers}${NC}"
    echo -e "${BOLD}$(printf "%${#headers}s" | tr " " "-")${NC}"
    
    # Print each row
    for row in "${rows[@]}"; do
        echo "$row"
    done
    echo
}

# Function: Display version and system info
show_system_info() {
    local os_version=$(cat /etc/os-release 2>/dev/null | grep "PRETTY_NAME" | cut -d "=" -f 2 | tr -d '"')
    local kernel_version=$(uname -r)
    local hostname=$(hostname)
    
    echo -e "${BLUE}System Information:${NC}"
    echo -e "  ${BOLD}OS:${NC}         ${os_version:-Unknown}"
    echo -e "  ${BOLD}Kernel:${NC}     ${kernel_version}"
    echo -e "  ${BOLD}Hostname:${NC}   ${hostname}"
    echo
}

# Function: Get terminal width
get_terminal_width() {
    if command_exists tput; then
        tput cols
    else
        echo "80"
    fi
}

# Function: Print a centered text
print_centered() {
    local text="$1"
    local width=$(get_terminal_width)
    local padding=$(( (width - ${#text}) / 2 ))
    
    printf "%${padding}s" ""
    echo "$text"
}

# Function: Print a box with text
print_box() {
    local text="$1"
    local width=$(get_terminal_width)
    local text_width=${#text}
    local box_width=$(( text_width + 4 ))
    
    if [ $box_width -gt $width ]; then
        box_width=$width
        text_width=$(( width - 4 ))
        text="${text:0:$text_width}"
    fi
    
    local padding=$(( (width - box_width) / 2 ))
    local line=$(printf "%${box_width}s" "" | tr " " "-")
    
    printf "%${padding}s" ""
    echo "+$line+"
    
    printf "%${padding}s" ""
    echo "| $text |"
    
    printf "%${padding}s" ""
    echo "+$line+"
}
