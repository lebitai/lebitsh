#!/bin/bash


function renew_ssl_by_domain()
{
    # Checking whether certbot is installation on server
    if ! command -v certbot &> /dev/null
    then
        echo "Certbot is not installed on server,installing..."
        sudo apt-get install certbot -y
    else
        echo "Certbot is already installed on server."

    # update the package of system.
    sudo apt-get update

    # Prompt user to enter the domain name
    read -p "Enter renew the domain name: " renew_domain

    # Prompt user to enter the path to the certificate
    read -p "Enter the full path of certificate: " cert_path

    cd $cert_path

    # Renew SSL certificate for domains using Certbot
    certbot renew -d $renew_domain --config-dir $cert_path --quiet


}

function exec_exit()
{
    exit 0
}


function main()
{
    clear
    echo "
__  _____    _    ___  _     ___   ____  _______     __
\ \/ /_ _|  / \  / _ \| |   |_ _| |  _ \| ____\ \   / /
 \  / | |  / _ \| | | | |    | |  | | | |  _|  \ \ / / 
 /  \ | | / ___ \ |_| | |___ | | _| |_| | |___  \ V /  
/_/\_\___/_/   \_\___/|_____|___(_)____/|_____|  \_/   
        "
    echo "Welcome to use this script to renew ssl certificate services."
    echo "================================================================"
    echo "Please select the operation to be performed:"
    echo "1. Renew ssl certificate"
    echo "2. Exit"
    read -p "Please enter an option (1-2): " OPTION

    case $OPTION in
    1) renew_ssl_by_domain;;
    2) exec_exit;;
    *) echo "Invalid option, please try again.";;
    esac
}

# main function
main