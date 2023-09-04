#!/bin/bash

echo "Preparation has begun"

sleep 3

# Step 1: Install required packages
echo "Step 1/2: Installing required packages..."
sudo apt-get upgrade -y > /dev/null 2>&1
sudo apt-get install curl wget jq libpq-dev libssl-dev build-essential pkg-config openssl ocl-icd-opencl-dev libopencl-clang-dev libgomp1 -y > /dev/null 2>&1

# Step 2: Install Docker if not installed
echo "Checking if Docker is already installed..."
if command -v docker >/dev/null 2>&1; then
    echo "Docker is already installed on this machine."
else
    echo "Installing Docker..."

    echo "Step 1/6: Installing dependencies..."
    sudo apt-get install curl gnupg apt-transport-https ca-certificates lsb-release -y >/dev/null 2>&1

    echo "Step 2/6: Adding Docker GPG key to keyring..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg >/dev/null 2>&1

    echo "Step 3/6: Adding Docker repository to sources list..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1

    echo "Step 4/6: Updating package list..."
    sudo apt-get update >/dev/null 2>&1

    echo "Step 5/6: Installing Docker..."
    sudo apt-get install docker-ce docker-ce-cli containerd.io -y >/dev/null 2>&1

    echo "Step 6/6: Docker installation completed."
    echo "Docker has been successfully installed."
fi

# Check if Docker Compose is installed
if command -v docker-compose >/dev/null 2>&1; then
    echo "Docker Compose is already installed on this machine."
else
    echo "Step 2/2: Installing Docker Compose..."
    
    # Download the Docker Compose binary
    sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose >/dev/null 2>&1

    # Apply executable permissions to the Docker Compose binary
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Verify the installation of Docker and Docker Compose
echo " "
docker --version
docker-compose --version

echo "The server is ready!"
