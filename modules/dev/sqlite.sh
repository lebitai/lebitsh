#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"

# Function: Install SQLite3
install_sqlite3() {
    show_brand
    section_header "SQLite3 Installation"
    
    # Check if root
    check_root
    
    # Check internet connection
    if ! check_internet; then
        exit 1
    fi
    
    # Check if SQLite3 is already installed
    if command_exists sqlite3; then
        current_version=$(sqlite3 --version | awk '{print $1}')
        info_msg "SQLite3 is already installed"
        info_msg "Current version: $current_version"
        
        read -p "Do you want to reinstall or update SQLite3? (y/n): " choice
        if [[ ! $choice =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    # Detect OS
    os_info=$(check_os)
    distro=$(echo "$os_info" | cut -d':' -f1)
    
    info_msg "Detected OS: $distro"
    
    # Install SQLite3 based on distribution
    case $distro in
        ubuntu|debian)
            show_progress "Installing SQLite3"
            apt-get update -qq >/dev/null
            apt-get install -y sqlite3 libsqlite3-dev >/dev/null 2>&1
            
            if [ $? -eq 0 ]; then
                complete_progress_success
            else
                complete_progress_failure
                error_msg "Failed to install SQLite3"
                exit 1
            fi
            ;;
            
        centos|rhel|fedora|rocky|almalinux)
            show_progress "Installing SQLite3"
            if command_exists dnf; then
                dnf install -y sqlite sqlite-devel >/dev/null 2>&1
            else
                yum install -y sqlite sqlite-devel >/dev/null 2>&1
            fi
            
            if [ $? -eq 0 ]; then
                complete_progress_success
            else
                complete_progress_failure
                error_msg "Failed to install SQLite3"
                exit 1
            fi
            ;;
            
        *)
            error_msg "Unsupported distribution: $distro"
            info_msg "You may need to install SQLite3 manually"
            exit 1
            ;;
    esac
    
    # Verify installation
    if command_exists sqlite3; then
        installed_version=$(sqlite3 --version | awk '{print $1}')
        success_msg "SQLite3 $installed_version installed successfully!"
        
        # Optional: Install SQLite Browser if it's a desktop environment
        if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
            read -p "Do you want to install SQLite Browser (GUI tool)? (y/n): " install_browser
            if [[ $install_browser =~ ^[Yy]$ ]]; then
                # Install SQLite Browser
                case $distro in
                    ubuntu|debian)
                        show_progress "Installing SQLite Browser"
                        apt-get install -y sqlitebrowser >/dev/null 2>&1
                        ;;
                    centos|rhel|fedora)
                        show_progress "Installing SQLite Browser"
                        if command_exists dnf; then
                            dnf install -y sqlitebrowser >/dev/null 2>&1
                        else
                            yum install -y sqlitebrowser >/dev/null 2>&1
                        fi
                        ;;
                    *)
                        warning_msg "SQLite Browser installation not supported on this distribution"
                        ;;
                esac
                
                if command_exists sqlitebrowser; then
                    complete_progress_success
                    success_msg "SQLite Browser installed successfully!"
                else
                    complete_progress_failure
                    warning_msg "Failed to install SQLite Browser"
                fi
            fi
        fi
    else
        error_msg "Failed to install SQLite3"
        exit 1
    fi
    
    # Sample database creation
    read -p "Do you want to create a sample SQLite database? (y/n): " create_sample
    if [[ $create_sample =~ ^[Yy]$ ]]; then
        # Create a sample database
        local sample_dir
        if [ "$SUDO_USER" ]; then
            sample_dir=$(eval echo ~"$SUDO_USER")/sqlite_samples
            mkdir -p "$sample_dir"
            chown "$SUDO_USER":"$SUDO_USER" "$sample_dir"
        else
            sample_dir=$HOME/sqlite_samples
            mkdir -p "$sample_dir"
        fi
        
        local sample_db="$sample_dir/sample.db"
        
        show_progress "Creating sample database"
        sqlite3 "$sample_db" <<EOF
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (name, email) VALUES ('John Doe', 'john@example.com');
INSERT INTO users (name, email) VALUES ('Jane Smith', 'jane@example.com');
INSERT INTO users (name, email) VALUES ('Alice Johnson', 'alice@example.com');

CREATE TABLE tasks (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    title TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users (id)
);

INSERT INTO tasks (user_id, title, description, status) 
VALUES (1, 'Learn SQL', 'Study SQLite basics', 'completed');

INSERT INTO tasks (user_id, title, description) 
VALUES (1, 'Create a database', 'Design schema for project');

INSERT INTO tasks (user_id, title, description) 
VALUES (2, 'Data analysis', 'Analyze sales data using SQL');
EOF
        
        if [ -f "$sample_db" ]; then
            if [ "$SUDO_USER" ]; then
                chown "$SUDO_USER":"$SUDO_USER" "$sample_db"
            fi
            complete_progress_success
            success_msg "Sample database created at: $sample_db"
            
            info_msg "You can interact with the database using:"
            echo "  sqlite3 $sample_db"
            echo ""
            info_msg "Sample queries to try:"
            echo "  .tables                           # List all tables"
            echo "  SELECT * FROM users;              # View all users"
            echo "  SELECT * FROM tasks;              # View all tasks"
            echo "  .schema users                     # View table schema"
        else
            complete_progress_failure
            error_msg "Failed to create sample database"
        fi
    fi
}

# Run the main function
install_sqlite3
