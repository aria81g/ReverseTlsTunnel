#!/bin/bash

# Function to check if wget is installed, and install it if not
check_dependencies() {
    if ! command -v wget &> /dev/null; then
        echo "wget is not installed. Installing..."
        sudo apt-get install wget
    fi
}

# Function to download and install RTT
install_rtt() {
    wget "https://raw.githubusercontent.com/radkesvat/ReverseTlsTunnel/master/install.sh" -O install.sh && chmod +x install.sh && bash install.sh
}

# Function to configure arguments based on user's choice
configure_arguments() {
    read -p "Which server do you want to use? (Enter '1' for Iran or '2' for Foreign) : " server_choice
    read -p "Please Enter SNI (default : splus.ir): " sni
    sni=${sni:-splus.ir}

    if [ "$server_choice" == "2" ]; then
        arguments="--iran-ip:$server_ip --iran-port:443 --toip:127.0.0.1 --toport:multiport --password:123 --sni:$sni --terminate:24"
    elif [ "$server_choice" == "1" ]; then
        arguments="--lport:23-65535 --sni:$sni --password:123 --terminate:24"
    else
        echo "Invalid choice. Please enter '1' or '2'."
        exit 1
    fi
}

# Function to handle installation
install() {
    install_rtt

    # Change directory to /etc/systemd/system
    cd /etc/systemd/system

    # Determine server IP using curl and grep
    server_ip=$(ip -4 addr show | awk '/inet/ && !/127.0.0.1/ {gsub(/\/[0-9]+/, "", $2); print $2}')
    if [ -z "$server_ip" ]; then
        echo "Unable to determine server IP. Please check your internet connection."
        exit 1
    fi

    configure_arguments

    # Create a new service file named tunnel.service
    cat <<EOL > tunnel.service
[Unit]
Description=my tunnel service

[Service]
User=root
WorkingDirectory=/root
ExecStart=/root/RTT $arguments
Restart=always

[Install]
WantedBy=multi-user.target
EOL

    # Reload systemctl daemon and start the service
    sudo systemctl daemon-reload
    sudo systemctl start tunnel.service
    sudo systemctl enable tunnel.service
}

# Function to handle uninstallation
uninstall() {
    # Check if the service is installed
    if [ ! -f "/etc/systemd/system/tunnel.service" ]; then
        echo "The service is not installed."
        return
    fi

    # Stop and disable the service
    sudo systemctl stop tunnel.service
    sudo systemctl disable tunnel.service

    # Remove service file
    sudo rm /etc/systemd/system/tunnel.service
    sudo rm RTT
    sudo rm install.sh

    echo "Uninstallation completed successfully."
}

# Main menu
check_dependencies
clear
echo "Created by --> Peyman "
echo " -1-------#- Reverse Tls Tunnel -#--------"
echo "1) Install"
echo "2) Uninstall"
echo "0) Exit"

read -p "Please choose: " choice

case $choice in
    1)
        install
        ;;
    2)
        uninstall
        ;;
    0)
        exit
        ;;
    *)
        echo "Invalid choice. Please try again."
        ;;
esac
