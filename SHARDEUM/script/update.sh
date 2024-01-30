cd ~/.shardeum

# Check if port 8080 is in use and kill the process using it
PORT=8080
PID=$(lsof -t -i:$PORT -sTCP:LISTEN)
if [ -n "$PID" ]; then
  kill $PID || { echo "Failed to kill process on port $PORT. Aborting."; exit 1; }
fi

# Ensure Docker is installed
command -v docker &>/dev/null || { echo "'docker' is required but not installed. Aborting."; exit 1; }

# Check Docker Compose
if ! command -v docker-compose &>/dev/null && ! docker --help | grep -q "compose"; then
    echo "Neither docker-compose nor docker compose are available. Aborting."
    exit 1
fi

docker-safe() {
    command -v docker &>/dev/null || { echo "docker is not available. Aborting."; exit 1; }
    docker "$@" || sudo docker "$@" || { echo "Failed to run docker command. Aborting."; exit 1; }
}

docker-compose-safe() {
  cmd=$(command -v docker-compose || echo "docker compose")
  $cmd $@ || sudo $cmd $@ || { echo "Failed to run $cmd. Aborting."; exit 1; }
}

# Shutting down Docker Compose project if up
if docker-compose-safe ps | grep -q "Up"; then
  docker-compose-safe -f docker-compose.yml down &>/dev/null || { echo "Failed to shut down Docker Compose project. Aborting."; exit 1; }
fi

# Clearing old Docker images
docker-safe rmi -f test-dashboard local-dashboard registry.gitlab.com/shardeum/server

# Updating local repository
git pull origin main || { echo "Error updating local repository. Please check your Git setup."; exit 1; }

# Rebuilding local validator image
docker-safe build --no-cache -t local-dashboard -f Dockerfile --build-arg RUNDASHBOARD=y . || { echo "Failed to build the local validator image."; exit 1; }

# Launching updated Docker Compose project
docker-compose-safe -f docker-compose.yml up -d || { echo "Failed to launch Docker Compose project. Aborting."; exit 1; }

# Setting up log monitoring
[ -e /tmp/my_log_pipe ] && rm /tmp/my_log_pipe
mkfifo /tmp/my_log_pipe
(docker-safe logs -f shardeum-dashboard > /tmp/my_log_pipe) &
(grep -q 'done' < /tmp/my_log_pipe && kill $$) &
while ! grep -q 'done' /tmp/my_log_pipe 2>/dev/null; do
    echo -ne "Running Dashboard in progress...\r"
    sleep 1
done
rm /tmp/my_log_pipe

cd ~/script
echo "Update successful!"
