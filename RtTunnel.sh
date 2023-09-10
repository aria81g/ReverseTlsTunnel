#!/bin/bash

install() {
    # Download and install RTT
    wget "https://raw.githubusercontent.com/radkesvat/ReverseTlsTunnel/master/install.sh" -O install.sh && chmod +x install.sh && bash install.sh

    # Change directory to /etc/systemd/system
    cd /etc/systemd/system

    # Determine server IP using curl and grep
    server_ip=$(ip -4 addr show | awk '/inet/ && !/127.0.0.1/ {gsub(/\/[0-9]+/, "", $2); print $2}')
    if [ -z "$server_ip" ]; then
        echo "Unable to determine server IP. Please check your internet connection."
        exit 1
    fi

    # Ask the user to choose a server
    echo "Which server do you want to use? (Enter 'iran' or 'foreign') : "
    read server_choice

    # Ask the user for SNI or default to splus.ir
    echo "Enter SNI (default is splus.ir): "
    read sni
    sni=${sni:-splus.ir}

    # Determine arguments based on user's choice
    if [ "$server_choice" == "foreign" ]; then
        arguments="./RTT --kharej --iran-ip:$server_ip --iran-port:443 --toip:127.0.0.1 --toport:multiport --password:123 --sni:$sni"
    elif [ "$server_choice" == "iran" ]; then
        arguments="./RTT --iran --lport:23-65535 --sni:$sni --password:123"
    else
        echo "Invalid choice. Please enter 'iran' or 'foreign'."
        exit 1
    fi

    # Create a new service file named tunnel.service
    cat <<EOL > tunnel.service
[Unit]
Description=my tunnel service

[Service]
User=root
WorkingDirectory=/root
ExecStart=/root/RTT $arguments --terminate:24
Restart=always

[Install]
WantedBy=multi-user.target
EOL

    # Reload systemctl daemon and start the service
    sudo systemctl daemon-reload
    sudo systemctl start tunnel.service
    sudo systemctl enable tunnel.service
}

uninstall() {
    # Stop and disable the service
    sudo systemctl stop tunnel.service
    sudo systemctl disable tunnel.service

    # Remove service file
    sudo rm /etc/systemd/system/tunnel.service

    # Optionally, remove RTT files or configurations
}

# Check the argument provided by the user
while true; do
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
done
