#!/bin/bash

# Ensure Docker is installed
command -v docker &>/dev/null || { echo >&2 "'docker' is required but not installed. See https://gitlab.com/shardeum/validator/dashboard/-/tree/dashboard-gui-nextjs#how-to for details."; exit 1; }

# Check Docker Compose
if command -v docker-compose &>/dev/null; then
    echo "Docker-compose is available."
elif docker --help | grep -q "compose"; then
    echo "Docker compose subcommand is available."
else
    echo "Neither docker-compose nor docker compose are available."
    exit 1
fi

docker-safe() {
    if ! command -v docker &>/dev/null; then
        echo "docker is not available."
        exit 1
    fi

    if ! docker "$@"; then
        echo "Failed to run docker command. Retrying with sudo..."
        sudo docker "$@"
    fi
}

# Replacing safe_execute docker-down.sh
echo "Shutting down Docker Compose project if up..."
docker-compose-safe() {
  if command -v docker-compose &>/dev/null; then
    cmd="docker-compose"
  elif docker --help | grep -q "compose"; then
    cmd="docker compose"
  else
    echo "docker-compose or docker compose is not installed on this machine"
    exit 1
  fi

  if ! $cmd $@; then
    echo "Trying again with sudo..."
    sudo $cmd $@
  fi
}

docker-compose-safe ps | grep -q "Up"
if [ $? -eq 0 ]; then
  echo "Docker Compose project is up"
  docker-compose-safe -f docker-compose.yml down
else
  echo "Docker Compose project is not up"
fi

# Replacing safe_execute cleanup.sh
echo "Clearing old Docker images..."
docker-safe rmi -f test-dashboard
docker-safe rmi -f local-dashboard
docker-safe rmi -f registry.gitlab.com/shardeum/server

# Updating local repository
echo "Updating local repository..."
if ! git pull origin main; then
    echo "Error updating local repository. Please check your Git setup."
    exit 1
fi

echo "Rebuilding local validator image..."
if ! docker-safe build --no-cache -t local-dashboard -f Dockerfile --build-arg RUNDASHBOARD=y .; then
    echo "Failed to build the local validator image."
    exit 1
fi

# Replacing safe_execute docker-up.sh
echo "Launching updated Docker Compose project..."
docker-compose-safe -f docker-compose.yml up -d

echo "Image initialization in progress. Please wait..."
if ! (docker-safe logs -f shardeum-dashboard &> /dev/null) | grep -q 'done'; then
    echo "Error starting the image. Please check the Docker logs for details."
    exit 1
fi

echo "Update successful!"

