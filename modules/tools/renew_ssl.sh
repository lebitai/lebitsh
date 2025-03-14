#!/bin/bash

# Get the absolute path of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_DIR="${SCRIPT_DIR}/../../common"

# Source common functions
source "${COMMON_DIR}/utils.sh"
source "${COMMON_DIR}/ui.sh"

# Function: Renew SSL certificates using certbot
renew_ssl_certificates() {
    show_brand
    section_header "SSL Certificate Renewal"
    
    # Check if root
    check_root
    
    # Check if certbot is installed
    if ! command_exists certbot; then
        warning_msg "Certbot is not installed"
        
        read -p "Do you want to install Certbot? (y/n): " install_certbot
        if [[ $install_certbot =~ ^[Yy]$ ]]; then
            # Install certbot based on distribution
            os_info=$(check_os)
            distro=$(echo "$os_info" | cut -d':' -f1)
            
            case $distro in
                ubuntu|debian)
                    show_progress "Installing Certbot"
                    apt-get update -qq >/dev/null
                    apt-get install -y certbot >/dev/null 2>&1
                    ;;
                centos|rhel|fedora|rocky|almalinux)
                    show_progress "Installing Certbot"
                    if command_exists dnf; then
                        dnf install -y certbot >/dev/null 2>&1
                    else
                        yum install -y certbot >/dev/null 2>&1
                    fi
                    ;;
                *)
                    complete_progress_failure
                    error_msg "Unsupported distribution: $distro"
                    info_msg "Please install Certbot manually following the instructions at:"
                    echo "  https://certbot.eff.org/instructions"
                    exit 1
                    ;;
            esac
            
            if command_exists certbot; then
                complete_progress_success
                success_msg "Certbot installed successfully"
            else
                complete_progress_failure
                error_msg "Failed to install Certbot"
                exit 1
            fi
        else
            error_msg "Certbot is required for SSL certificate renewal"
            exit 1
        fi
    fi
    
    # Check if any certificates exist
    if [ ! -d /etc/letsencrypt/live ]; then
        error_msg "No Let's Encrypt certificates found"
        info_msg "You need to obtain certificates first using Certbot"
        info_msg "For more information, visit: https://certbot.eff.org/instructions"
        exit 1
    fi
    
    # List existing certificates
    info_msg "Existing SSL certificates:"
    domains=$(find /etc/letsencrypt/live -type d -name "*" | grep -v README | xargs -I{} basename {})
    
    if [ -z "$domains" ]; then
        error_msg "No certificates found"
        exit 1
    fi
    
    # Display domains
    echo "$domains" | nl -v 1
    echo ""
    
    # Offer renewal options
    options=(
        "Renew specific certificate"
        "Renew all certificates"
        "Test renewal (dry run)"
        "Cancel"
    )
    
    show_menu "Select an option:" "${options[@]}"
    choice=$?
    
    case $choice in
        1)
            # Renew specific certificate
            read -p "Enter the number of the domain to renew: " domain_num
            domain=$(echo "$domains" | sed -n "${domain_num}p")
            
            if [ -z "$domain" ]; then
                error_msg "Invalid selection"
                exit 1
            fi
            
            info_msg "Renewing certificate for: $domain"
            show_progress "Renewing certificate"
            certbot renew --cert-name "$domain" >/dev/null 2>&1
            
            if [ $? -eq 0 ]; then
                complete_progress_success
                success_msg "Certificate renewed successfully for $domain"
                
                # Restart web server if needed
                read -p "Do you want to restart web server (nginx/apache2)? (y/n): " restart_web
                if [[ $restart_web =~ ^[Yy]$ ]]; then
                    if command_exists systemctl; then
                        if systemctl is-active --quiet nginx; then
                            show_progress "Restarting nginx"
                            systemctl restart nginx >/dev/null 2>&1
                            complete_progress_success
                        elif systemctl is-active --quiet apache2; then
                            show_progress "Restarting apache2"
                            systemctl restart apache2 >/dev/null 2>&1
                            complete_progress_success
                        else
                            warning_msg "No active web server (nginx/apache2) found"
                        fi
                    else
                        warning_msg "Cannot restart web server: systemctl not available"
                    fi
                fi
            else
                complete_progress_failure
                error_msg "Failed to renew certificate for $domain"
            fi
            ;;
        2)
            # Renew all certificates
            info_msg "Renewing all certificates"
            show_progress "Renewing certificates"
            certbot renew >/dev/null 2>&1
            
            if [ $? -eq 0 ]; then
                complete_progress_success
                success_msg "All certificates renewed successfully"
                
                # Restart web server if needed
                read -p "Do you want to restart web server (nginx/apache2)? (y/n): " restart_web
                if [[ $restart_web =~ ^[Yy]$ ]]; then
                    if command_exists systemctl; then
                        if systemctl is-active --quiet nginx; then
                            show_progress "Restarting nginx"
                            systemctl restart nginx >/dev/null 2>&1
                            complete_progress_success
                        elif systemctl is-active --quiet apache2; then
                            show_progress "Restarting apache2"
                            systemctl restart apache2 >/dev/null 2>&1
                            complete_progress_success
                        else
                            warning_msg "No active web server (nginx/apache2) found"
                        fi
                    else
                        warning_msg "Cannot restart web server: systemctl not available"
                    fi
                fi
            else
                complete_progress_failure
                error_msg "Failed to renew certificates"
            fi
            ;;
        3)
            # Test renewal (dry run)
            info_msg "Performing test renewal (dry run)"
            certbot renew --dry-run
            ;;
        4|*)
            # Cancel
            info_msg "Operation cancelled"
            exit 0
            ;;
    esac
    
    # Offer to set up automated renewal
    echo ""
    read -p "Do you want to set up automated renewal? (y/n): " setup_auto
    if [[ $setup_auto =~ ^[Yy]$ ]]; then
        # Create renewal script
        renewal_script="/usr/local/bin/renew_certificates.sh"
        
        cat << 'EOF' > "$renewal_script"
#!/bin/bash
# Automated certificate renewal script
# Created by Lebit.sh SSL renewal utility

# Renew certificates
certbot renew --quiet

# Check if nginx is running and reload it
if systemctl is-active --quiet nginx; then
    systemctl reload nginx
fi

# Check if apache2 is running and reload it
if systemctl is-active --quiet apache2; then
    systemctl reload apache2
fi
EOF
        
        chmod +x "$renewal_script"
        
        # Create log directory
        mkdir -p /var/log/certbot
        
        # Add cron job for certificate renewal
        if add_cron_job "$renewal_script" "0 3 * * *"; then
            success_msg "Automated certificate renewal configured successfully"
            info_msg "Certificates will be checked daily at 3:00 AM"
        else
            error_msg "Failed to set up automated renewal"
        fi
    fi
}

# Run the main function
renew_ssl_certificates
