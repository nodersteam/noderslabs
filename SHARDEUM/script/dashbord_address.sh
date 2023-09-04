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

# Construct the dashboard address
DASHBOARD_ADDRESS="https://$IP_ADDRESS:8080"

# Test the dashboard address for a response
wget --spider -q $DASHBOARD_ADDRESS

if [ $? -ne 0 ]; then
    echo "Dashboard might not be active. Please check the node's state."
    exit 1
else
    echo $DASHBOARD_ADDRESS
fi
