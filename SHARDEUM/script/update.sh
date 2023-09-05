#!/bin/bash

cd ~/.shardeum

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
  docker-compose-safe -f docker-compose.yml down &>/dev/null
else
  echo "Docker Compose project is not up"
fi

# Replacing safe_execute cleanup.sh
echo "Clearing old Docker images..."
docker-safe rmi -f test-dashboard > /dev/null 2>&1
docker-safe rmi -f local-dashboard > /dev/null 2>&1
docker-safe rmi -f registry.gitlab.com/shardeum/server > /dev/null 2>&1

# Updating local repository
echo "Updating local repository..."
if ! git pull origin main > /dev/null 2>&1 ; then
    echo "Error updating local repository. Please check your Git setup."
    exit 1
fi

echo "Rebuilding local validator image..."
if ! docker-safe build --no-cache -t local-dashboard -f Dockerfile --build-arg RUNDASHBOARD=y . &>/dev/null; then
    echo "Failed to build the local validator image."
    exit 1
fi

# Replacing safe_execute docker-up.sh
echo "Launching updated Docker Compose project..."
docker-compose-safe -f docker-compose.yml up -d &>/dev/null

[ -e /tmp/my_log_pipe ] && rm /tmp/my_log_pipe

mkfifo /tmp/my_log_pipe

# Check for logs
echo "Starting image. This may take some time..."
(docker-safe logs -f shardeum-dashboard > /tmp/my_log_pipe) > /dev/null 2>&1 &
(grep -q 'done' < /tmp/my_log_pipe && kill $$) &
while ! grep -q 'done' /tmp/my_log_pipe 2>/dev/null; do
    echo -ne "Running Dashboard in progress...\r"
    sleep 1
done

rm /tmp/my_log_pipe
cd ~/script
echo "Update successful!"

