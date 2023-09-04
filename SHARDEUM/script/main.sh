#!/usr/bin/env bash
clear

# Logo
echo "                        _____ _   _   ___  ____________ _____ _   ____  ___                       "
echo "                       /  ___| | | | / _ \ | ___ \  _  \  ___| | | |  \/  |                       "
echo "                       \ \`--.| |_| |/ /_\ \| |_/ / | | | |__ | | | | .  . |                      "
echo "                        \`--. \  _  ||  _  ||    /| | | |  __|| | | | |\/| |                      "
echo "                       /\__/ / | | || | | || |\ \| |/ /| |___| |_| | |  | |                       "
echo "                       \____/\_| |_/\_| |_/\_| \_|___/ \____/ \___/\_|  |_|    NODE INSTALL SCRIPT"
echo " "

while true
do
    PS3='Select an action: '
    options=(
    "Prepare the server for installation"
    "Install Shardeum Node"
    "Update Node"
    "Logs"
    "Dashboard address"
    "Stop and delete node"
    "Exit")

    select opt in "${options[@]}"
    do
        case $opt in
            "Prepare the server for installation")
                ./server.sh
                break
                ;;
            "Install Shardeum Node")
                ./install.sh
                break
                ;;
            "Update Node")
                ./update.sh
                break
                ;;
            "Logs")
                ./logs.sh
                break
                ;;
            "Dashboard address")
                ./dashboard_address.sh
                break
                ;;
            "Stop and delete node")
                ./delete_node.sh
                break
                ;;
            "Exit")
                exit
                ;;
            *)
                echo "Invalid option $REPLY"
                ;;
        esac
    done
done
