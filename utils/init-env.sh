#!bin/bash

function init_env()
{
    echo "Init env of Linux"
    echo "alias apt-up='apt update && apt upgrade -y'" >> ~/.bashrc
    source ~/.bashrc
}


main()
{
    clear
    echo "
__  _____    _    ___  _     ___   ____  _______     __
\ \/ /_ _|  / \  / _ \| |   |_ _| |  _ \| ____\ \   / /
 \  / | |  / _ \| | | | |    | |  | | | |  _|  \ \ / / 
 /  \ | | / ___ \ |_| | |___ | | _| |_| | |___  \ V /  
/_/\_\___/_/   \_\___/|_____|___(_)____/|_____|  \_/   
        "
    echo "Welcome to XIAOLIDEV init-env script."
    echo "================================================================"
    echo "Please select the operation to be performed:"
    echo "1. Init env of Linux"
    echo "2. Exit"
    read -p "Please enter an option (1-2): " OPTION

    case $OPTION in
    1) init_env;;
    2) exec_exit;;
    *) echo "Invalid option, please try again.";;
    esac
}
main