#!/usr/bin/env bash
# Function to pause script execution until any key is pressed

clear

pause() {
    echo "Press any key to continue..."
    read -s -n 1
    clear
}

display_logo_and_info() {
    clear

    # Logo
echo "  _____ _   _   ___  ____________ _____ _   ____  ___                       "
echo " /  ___| | | | / _ \ | ___ \  _  \  ___| | | |  \/  |                       "
echo " \ \`--.| |_| |/ /_\ \| |_/ / | | | |__ | | | | .  . |                      "
echo "  \`--. \  _  ||  _  ||    /| | | |  __|| | | | |\/| |                      "
echo " /\__/ / | | || | | || |\ \| |/ /| |___| |_| | |  | |                       "
echo " \____/\_| |_/\_| |_/\_| \_|___/ \____/ \___/\_|  |_|                       "
echo -e "\033[34m Node installation script powered by [NODERS]TEAM \033[0m        "
echo " "

    # Attempt to fetch the IP address
    IP_ADDRESS=$(wget -qO- eth0.me)

    # Check if we successfully fetched the IP address
    if [ -z "$IP_ADDRESS" ]; then
        echo "Error: Failed to fetch the IP address. Please ensure you have an active internet connection and try again."
        exit 1
    fi

    # Construct the dashboard address
    DASHBOARD_ADDRESS="https://$IP_ADDRESS:8080"

    # Check if 'shardeum-dashboard' is running and has a binding to port 8080
if command -v docker &> /dev/null; then
    if docker ps | grep "shardeum-dashboard" | grep -q "0.0.0.0:8080->8080/tcp" ; then
        echo -e "Your dashboard is available at: \e[32m$DASHBOARD_ADDRESS\e[0m"
        echo " "
    fi
fi

}

goodbye_message() {
    clear
    # Logo
    echo "  _____ _   _   ___  ____________ _____ _   ____  ___                       "
    echo " /  ___| | | | / _ \ | ___ \  _  \  ___| | | |  \/  |                       "
    echo " \ \`--.| |_| |/ /_\ \| |_/ / | | | |__ | | | | .  . |                      "
    echo "  \`--. \  _  ||  _  ||    /| | | |  __|| | | | |\/| |                      "
    echo " /\__/ / | | || | | || |\ \| |/ /| |___| |_| | |  | |                       "
    echo " \____/\_| |_/\_| |_/\_| \_|___/ \____/ \___/\_|  |_|                       "
    echo -e "\033[5m STAY WITH SHARDEUM \033[0m                                       "
    sleep 2
    clear
}

display_logo_and_info

options=(
"Install Shardeum Node"
"Update Node"
"Logs"
"Stop and delete node"
"Exit")

while true
do
    PS3=""
    for i in "${!options[@]}"; do
        echo "$((i+1))) ${options[$i]}"
    done
    echo -n "Select an action: "
    read REPLY
    case $REPLY in

        1)
            ./install.sh
            pause
            ;;
        2)
            ./update.sh
            pause
            ;;
        3)
            ./logs.sh
            pause
            ;;
        4)
            ./delete_node.sh
            pause
            ;;
        5)  
            goodbye_message
            exit
            ;;
        *)
            echo "Invalid option $REPLY"
            pause
            ;;
    esac
    display_logo_and_info
done
