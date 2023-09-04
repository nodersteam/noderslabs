#!/bin/bash

docker-compose-safe() {
    local cmd

    if command -v docker-compose &>/dev/null; then
        cmd="docker-compose"
    elif docker --help | grep -q "compose"; then
        cmd="docker compose"
    else
        echo "Neither docker-compose nor docker compose are installed on this machine."
        exit 1
    fi

    if ! $cmd "$@" &>/dev/null; then
        echo "Encountered an issue. Trying again with sudo..."
        sudo $cmd "$@" &>/dev/null
    fi
}

cd $HOME/.shardeum || {
    echo "Error: Unable to change to the .shardeum directory."
    exit 1
}

echo "Step 1: Checking the status of the Docker Compose project..."

if docker-compose logs | grep -q "done" &>/dev/null; then
    echo "Step 2: Docker Compose project is up, tearing it down..."
    docker-compose-safe -f docker-compose.yml down

    echo "Step 3: Removing the .shardeum directory in the home folder..."
    cd && rm -rf $HOME/.shardeum &>/dev/null
    echo "Node deleted successfully."
else
    echo "Step 2: Docker Compose project is not up."
fi
