#!/bin/bash

# Display information to the user
echo "Copy this address and paste it in your browser. The dashboard will open where you can start the node and perform a stake."

# Attempt to fetch the IP address
IP_ADDRESS=$(wget -qO- eth0.me)

# Check if we successfully fetched the IP address
if [ -z "$IP_ADDRESS" ]; then
    echo "Error: Failed to fetch the IP address. Please ensure you have an active internet connection and try again."
    exit 1
fi

# If everything is fine, display the dashboard address
DASHBOARD_ADDRESS="https://$IP_ADDRESS:8080"
echo $DASHBOARD_ADDRESS
