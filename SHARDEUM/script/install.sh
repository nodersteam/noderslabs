#!/usr/bin/env bash
set -e
SCRIPT_EXECUTED=false
# Get the environment/OS
environment=$(uname)

# Function to exit with an error message
exit_with_error() {
    echo "Error: $1"
    exit 1
}

# Check the operating system and get the processor information
case "$environment" in
    Linux)
        processor=$(uname -m)
        ;;
    Darwin)
        processor=$(uname -m)
        ;;
    *MINGW*)
        exit_with_error "$environment (Windows) environment not yet supported. Please use WSL (WSL2 recommended) or a Linux VM. Exiting installer."
        ;;
    *)
        processor="Unknown"
        ;;
esac

echo "Preparation has begun"
sleep 3

# Check if necessary packages are installed and if not, install them
required_packages=("curl" "wget" "jq" "libpq-dev" "libssl-dev" "build-essential" "pkg-config" "openssl" "ocl-icd-opencl-dev" "libopencl-clang-dev" "libgomp1")
for package in "${required_packages[@]}"; do
    if ! dpkg -l | grep -q $package; then
        echo "Installing $package..."
        sudo apt-get install $package -y > /dev/null 2>&1
    else
        echo "$package is already installed."
    fi
done

# Check if Docker is installed
if command -v docker >/dev/null 2>&1; then
    echo "Docker is already installed on this machine."
    docker --version
else
    echo "Installing Docker..."

    echo "Step 1/5: Adding Docker GPG key to keyring..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg >/dev/null 2>&1

    echo "Step 2/5: Adding Docker repository to sources list..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1

    echo "Step 3/5: Updating package list..."
    sudo apt-get update >/dev/null 2>&1

    echo "Step 4/5: Installing Docker..."
    sudo apt-get install docker-ce docker-ce-cli containerd.io -y >/dev/null 2>&1

    echo "Step 5/5: Docker installation completed."
    echo "Docker has been successfully installed."

    echo "Docker has been successfully installed."
fi

# Check if Docker Compose is installed
if command -v docker-compose >/dev/null 2>&1; then
    echo "Docker Compose is already installed on this machine."
    docker-compose --version
else
    echo "Installing Docker Compose..."
    
    # Download the Docker Compose binary
    sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose >/dev/null 2>&1

    # Apply executable permissions to the Docker Compose binary
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Check for ARM processor or Unknown and exit if true, meaning the installer is not supported by the processor
if [[ "$processor" == *"arm"* || "$processor" == "Unknown" ]]; then
    exit_with_error "$processor not yet supported. Exiting installer."
fi

# Print the detected environment and processor
echo "$environment environment with $processor found."


# Check if any hashing command is available
if ! (command -v openssl > /dev/null || command -v shasum > /dev/null || command -v sha256sum > /dev/null); then
  echo "No supported hashing commands found."
  read -p "Would you like to install openssl? (y/n) " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Detect package manager and install openssl
    if command -v apt-get > /dev/null; then
      sudo apt-get update && sudo apt-get install -y openssl
    elif command -v yum > /dev/null; then
      sudo yum install -y openssl
    elif command -v dnf > /dev/null; then
      sudo dnf install -y openssl
    else
      echo "Your package manager is not supported. Please install openssl manually."
      exit 1
    fi
  else
    echo "Please install openssl, shasum, or sha256sum and try again."
    exit 1
  fi
fi


read -p "During this early stage of Betanet the Shardeum team will be collecting some performance and debugging info from your node to help improve future versions of the software.
This is only temporary and will be discontinued as we get closer to mainnet.
Thanks for running a node and helping to make Shardeum better.

By running this installer, you agree to allow the Shardeum team to collect this data. (Y/n)?: " WARNING_AGREE
WARNING_AGREE=$(echo "$WARNING_AGREE" | tr '[:upper:]' '[:lower:]')
WARNING_AGREE=${WARNING_AGREE:-y}

if [ $WARNING_AGREE != "y" ];
then
  echo "Diagnostic data collection agreement not accepted. Exiting installer."
  exit
fi

read -p "What base directory should the node use (default ~/.shardeum): " input

# Set default value if input is empty
input=${input:-~/.shardeum}

# Check if input starts with "/" or "~/", if not, add "~/"
if [[ ! $input =~ ^(/|~\/) ]]; then
  input="~/$input"
fi

# Reprompt if not alphanumeric characters, tilde, forward slash, underscore, period, hyphen, or contains spaces
while [[ ! $input =~ ^[[:alnum:]_.~/-]+$ || $input =~ .*[\ ].* ]]; do
  read -p "Error: The directory name contains invalid characters or spaces.
Allowed characters are alphanumeric characters, tilde, forward slash, underscore, period, and hyphen.
Please enter a valid base directory (default ~/.shardeum): " input

  # Check if input starts with "/" or "~/", if not, add "~/"
  if [[ ! $input =~ ^(/|~\/) ]]; then
    input="~/$input"
  fi
done

# Remove spaces from the input
input=${input// /}

# Echo the final directory used
echo "The base directory is set to: $input"

# Replace leading tilde (~) with the actual home directory path
NODEHOME="${input/#\~/$HOME}" # support ~ in path

# Check all things that will be needed for this script to succeed like access to docker and docker-compose
# If any check fails exit with a message on what the user needs to do to fix the problem
command -v git >/dev/null 2>&1 || { echo >&2 "'git' is required but not installed."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo >&2 "'docker' is required but not installed. See https://gitlab.com/shardeum/validator/dashboard/-/tree/dashboard-gui-nextjs#how-to for details."; exit 1; }
if command -v docker-compose &>/dev/null; then
  echo "docker-compose is installed on this machine"
elif docker --help | grep -q "compose"; then
  echo "docker compose subcommand is installed on this machine"
else
  echo "docker-compose or docker compose is not installed on this machine"
  exit 1
fi

export DOCKER_DEFAULT_PLATFORM=linux/amd64

docker-safe() {
  if ! command -v docker &>/dev/null; then
    echo "docker is not installed on this machine"
    exit 1
  fi

  if ! docker $@; then
    echo "Trying again with sudo..." >&2
    sudo docker $@
  fi
}

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

get_ip() {
  local ip
  if command -v ip >/dev/null; then
    ip=$(ip addr show $(ip route | awk '/default/ {print $5}') | awk '/inet/ {print $2}' | cut -d/ -f1 | head -n1)
  elif command -v netstat >/dev/null; then
    # Get the default route interface
    interface=$(netstat -rn | awk '/default/{print $4}' | head -n1)
    # Get the IP address for the default interface
    ip=$(ifconfig "$interface" | awk '/inet /{print $2}')
  else
    echo "Error: neither 'ip' nor 'ifconfig' command found. Submit a bug for your OS."
    return 1
  fi
  echo $ip
}

get_external_ip() {
  external_ip=''
  external_ip=$(curl -s https://api.ipify.org)
  if [[ -z "$external_ip" ]]; then
    external_ip=$(curl -s http://checkip.dyndns.org | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
  fi
  if [[ -z "$external_ip" ]]; then
    external_ip=$(curl -s http://ipecho.net/plain)
  fi
  if [[ -z "$external_ip" ]]; then
    external_ip=$(curl -s https://icanhazip.com/)
  fi
    if [[ -z "$external_ip" ]]; then
    external_ip=$(curl --header  "Host: icanhazip.com" -s 104.18.114.97)
  fi
  if [[ -z "$external_ip" ]]; then
    external_ip=$(get_ip)
    if [ $? -eq 0 ]; then
      echo "The IP address is: $IP"
    else
      external_ip="localhost"
    fi
  fi
  echo $external_ip
}

hash_password() {
  local input="$1"
  local hashed_password

  # Try using openssl
  if command -v openssl > /dev/null; then
    hashed_password=$(echo -n "$input" | openssl dgst -sha256 -r | awk '{print $1}')
    echo "$hashed_password"
    return 0
  fi

  # Try using shasum
  if command -v shasum > /dev/null; then
    hashed_password=$(echo -n "$input" | shasum -a 256 | awk '{print $1}')
    echo "$hashed_password"
    return 0
  fi

  # Try using sha256sum
  if command -v sha256sum > /dev/null; then
    hashed_password=$(echo -n "$input" | sha256sum | awk '{print $1}')
    echo "$hashed_password"
    return 0
  fi

  return 1
}

if [[ $(docker-safe info 2>&1) == *"Cannot connect to the Docker daemon"* ]]; then
    echo "Docker daemon is not running"
    exit 1
else
    echo "Docker daemon is running"
fi

CURRENT_DIRECTORY=$(pwd)

# DEFAULT VALUES FOR USER INPUTS
DASHPORT_DEFAULT=8080
EXTERNALIP_DEFAULT=auto
INTERNALIP_DEFAULT=auto
SHMEXT_DEFAULT=9001
SHMINT_DEFAULT=10001
PREVIOUS_PASSWORD=none

#Check if container exists
IMAGE_NAME="registry.gitlab.com/shardeum/server:latest"
CONTAINER_ID=$(docker-safe ps -qf "ancestor=local-dashboard")
if [ ! -z "${CONTAINER_ID}" ]; then
  echo "CONTAINER_ID: ${CONTAINER_ID}"
  echo "Existing container found. Reading settings from container."

  # Assign output of read_container_settings to variable
  if ! ENV_VARS=$(docker inspect --format="{{range .Config.Env}}{{println .}}{{end}}" "$CONTAINER_ID"); then
    ENV_VARS=$(sudo docker inspect --format="{{range .Config.Env}}{{println .}}{{end}}" "$CONTAINER_ID")
  fi

  if ! docker-safe cp "${CONTAINER_ID}:/home/node/app/cli/build/secrets.json" ./; then
    echo "Container does not have secrets.json"
  else
    echo "Reusing secrets.json from container"
  fi

  # CHECK IF VALIDATOR IS ALREADY RUNNING
  set +e
  status=$(docker-safe exec "${CONTAINER_ID}" operator-cli status 2>/dev/null)
  check=$?
  set -e

  if [ $check -eq 0 ]; then
    # The command ran successfully
    status=$(awk '/state:/ {print $2}' <<< $status)
    if [ "$status" = "active" ] || [ "$status" = "syncing" ]; then
      read -p "Your node is $status and upgrading will cause the node to leave the network unexpectedly and lose the stake amount.
      Do you really want to upgrade now (y/N)?" REALLYUPGRADE
      REALLYUPGRADE=$(echo "$REALLYUPGRADE" | tr '[:upper:]' '[:lower:]')
      REALLYUPGRADE=${REALLYUPGRADE:-n}

      if [ "$REALLYUPGRADE" == "n" ]; then
        exit 1
      fi
    else
      echo "Validator process is not online"
    fi
  else
    read -p "The installer was unable to determine if the existing node is active.
    An active node unexpectedly leaving the network will lose it's stake amount.
    Do you really want to upgrade now (y/N)?" REALLYUPGRADE
    REALLYUPGRADE=$(echo "$REALLYUPGRADE" | tr '[:upper:]' '[:lower:]')
    REALLYUPGRADE=${REALLYUPGRADE:-n}

    if [ "$REALLYUPGRADE" == "n" ]; then
      exit 1
    fi
  fi

  docker-safe stop "${CONTAINER_ID}"
  docker-safe rm "${CONTAINER_ID}"

  # UPDATE DEFAULT VALUES WITH SAVED VALUES
  DASHPORT_DEFAULT=$(echo $ENV_VARS | grep -oP 'DASHPORT=\K[^ ]+') || DASHPORT_DEFAULT=8080
  EXTERNALIP_DEFAULT=$(echo $ENV_VARS | grep -oP 'EXT_IP=\K[^ ]+') || EXTERNALIP_DEFAULT=auto
  INTERNALIP_DEFAULT=$(echo $ENV_VARS | grep -oP 'INT_IP=\K[^ ]+') || INTERNALIP_DEFAULT=auto
  SHMEXT_DEFAULT=$(echo $ENV_VARS | grep -oP 'SHMEXT=\K[^ ]+') || SHMEXT_DEFAULT=9001
  SHMINT_DEFAULT=$(echo $ENV_VARS | grep -oP 'SHMINT=\K[^ ]+') || SHMINT_DEFAULT=10001
  PREVIOUS_PASSWORD=$(echo $ENV_VARS | grep -oP 'DASHPASS=\K[^ ]+') || PREVIOUS_PASSWORD=none
elif [ -f NODEHOME/.env ]; then
  echo "Existing NODEHOME/.env file found. Reading settings from file."

  # Read the NODEHOME/.env file into a variable. Use default installer directory if it exists.
  ENV_VARS=$(cat NODEHOME/.env)

  # UPDATE DEFAULT VALUES WITH SAVED VALUES
  DASHPORT_DEFAULT=$(echo $ENV_VARS | grep -oP 'DASHPORT=\K[^ ]+') || DASHPORT_DEFAULT=8080
  EXTERNALIP_DEFAULT=$(echo $ENV_VARS | grep -oP 'EXT_IP=\K[^ ]+') || EXTERNALIP_DEFAULT=auto
  INTERNALIP_DEFAULT=$(echo $ENV_VARS | grep -oP 'INT_IP=\K[^ ]+') || INTERNALIP_DEFAULT=auto
  SHMEXT_DEFAULT=$(echo $ENV_VARS | grep -oP 'SHMEXT=\K[^ ]+') || SHMEXT_DEFAULT=9001
  SHMINT_DEFAULT=$(echo $ENV_VARS | grep -oP 'SHMINT=\K[^ ]+') || SHMINT_DEFAULT=10001
  PREVIOUS_PASSWORD=$(echo $ENV_VARS | grep -oP 'DASHPASS=\K[^ ]+') || PREVIOUS_PASSWORD=none
fi

echo "Starting the installation process..."

# Check for user's choice on dashboard
read -p "Do you want to run the web based Dashboard? (Y/n): " RUNDASHBOARD
RUNDASHBOARD=$(echo "$RUNDASHBOARD" | tr '[:upper:]' '[:lower:]')
RUNDASHBOARD=${RUNDASHBOARD:-y}

if [ "$PREVIOUS_PASSWORD" != "none" ]; then
    read -p "Do you want to change the password for the Dashboard? (y/N): " CHANGEPASSWORD
    CHANGEPASSWORD=$(echo "$CHANGEPASSWORD" | tr '[:upper:]' '[:lower:]')
    CHANGEPASSWORD=${CHANGEPASSWORD:-n}
else
    CHANGEPASSWORD="y"
fi

# Password setup
if [ "$CHANGEPASSWORD" == "y" ]; then
    while true; do
        read -s -p "Set the password to access the Dashboard: " DASHPASS
        echo # New line for formatting
        if [ -z "$DASHPASS" ]; then
            echo "Password should not be empty. Please try again."
            continue
        else
            DASHPASS=$(hash_password "$DASHPASS")
            break
        fi
    done
else
    DASHPASS=$PREVIOUS_PASSWORD
    DASHPASS=$(hash_password "$DASHPASS")
fi

# Ensure password is hashed
if [ -z "$DASHPASS" ]; then
    echo "Failed to hash the password. Please ensure you have openssl."
    exit 1
fi

# Port setup for dashboard
while true; do
    read -p "Enter the port (1025-65536) to access the web based Dashboard (default $DASHPORT_DEFAULT): " DASHPORT
    DASHPORT=${DASHPORT:-$DASHPORT_DEFAULT}
    if ((DASHPORT >= 1025 && DASHPORT <= 65536)); then
        break
    else
        echo "Port out of range, try again."
    fi
done

# External IP setup
while true; do
    read -p "If you wish to set an explicit external IP, enter an IPv4 address (default=$EXTERNALIP_DEFAULT): " EXTERNALIP
    EXTERNALIP=${EXTERNALIP:-$EXTERNALIP_DEFAULT}
    if [[ $EXTERNALIP == "auto" ]] || [[ $EXTERNALIP =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        break
    else
        echo "Invalid IPv4 address. Please try again."
    fi
done

# Internal IP setup
while true; do
    read -p "If you wish to set an explicit internal IP, enter an IPv4 address (default=$INTERNALIP_DEFAULT): " INTERNALIP
    INTERNALIP=${INTERNALIP:-$INTERNALIP_DEFAULT}
    if [[ $INTERNALIP == "auto" ]] || [[ $INTERNALIP =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        break
    else
        echo "Invalid IPv4 address. Please try again."
    fi
done

# P2P communication ports
while true; do
    echo "To run a validator on the Sphinx network, you will need to open two ports in your firewall."
    echo "This allows p2p communication between nodes."
    read -p "Enter the first port (1025-65536) for p2p communication (default $SHMEXT_DEFAULT): " SHMEXT
    SHMEXT=${SHMEXT:-$SHMEXT_DEFAULT}
    read -p "Enter the second port (1025-65536) for p2p communication (default $SHMINT_DEFAULT): " SHMINT
    SHMINT=${SHMINT:-$SHMINT_DEFAULT}
    if ((SHMEXT >= 1025 && SHMEXT <= 65536)) && ((SHMINT >= 1025 && SHMINT <= 65536)); then
        break
    else
        echo "One or both ports are out of range, try again."
    fi
done

APPMONITOR="173.255.198.126"

# Check and remove existing directory
if [ -d "$NODEHOME" ]; then
  if [ "$NODEHOME" != "$(pwd)" ]; then
    echo "Removing existing directory $NODEHOME..."
    rm -rf "$NODEHOME" || { echo "Error: Could not remove $NODEHOME. Exiting."; exit 1; }
  else
    echo "Cannot delete current working directory. Please move to another directory and try again."
    exit 1
  fi
fi

# Clone the repository
echo "Cloning repository..."
git clone https://gitlab.com/shardeum/validator/dashboard.git ${NODEHOME} > /dev/null 2>&1 || { echo "Error: Failed to clone repository. Exiting script."; exit 1; }
cd ${NODEHOME} > /dev/null 2>&1
chmod a+x ./*.sh > /dev/null 2>&1

# Create .env file
echo "Setting up configuration..."
SERVERIP=$(get_external_ip)
LOCALLANIP=$(get_ip)
touch ./.env
cat >./.env <<EOL
EXT_IP=${EXTERNALIP}
INT_IP=${INTERNALIP}
EXISTING_ARCHIVERS=[{"ip":"45.79.8.251","port":4000,"publicKey":"840e7b59a95d3c5f5044f4bc62ab9fa94bc107d391001141410983502e3cde63"},{"ip":"66.228.59.166","port":4000,"publicKey":"7af699dd711074eb96a8d1103e32b589e511613ebb0c6a789a9e8791b2b05f34"},{"ip":"45.33.44.51","port":4000,"publicKey":"2db7c949632d26b87d7e7a5a4ad41c306f63ee972655121a37c5e4f52b00a542"}]
APP_MONITOR=${APPMONITOR}
DASHPASS=${DASHPASS}
DASHPORT=${DASHPORT}
SERVERIP=${SERVERIP}
LOCALLANIP=${LOCALLANIP}
SHMEXT=${SHMEXT}
SHMINT=${SHMINT}
EOL

# Docker build
# Docker build
echo "Building Docker image..."
cd ${NODEHOME} > /dev/null 2>&1 &&
docker-safe build --no-cache -t local-dashboard -f Dockerfile --build-arg RUNDASHBOARD=${RUNDASHBOARD} . > /dev/null 2>&1 || { echo "Error: Failed to build Docker image. Exiting."; exit 1; }

# Adjusting docker-compose based on OS
echo "Configuring Docker Compose..."
cd ${NODEHOME}
if [[ "$(uname)" == "Darwin" ]]; then
  sed "s/- '8080:8080'/- '$DASHPORT:$DASHPORT'/" docker-compose.tmpl > docker-compose.yml
  sed -i '' "s/- '9001-9010:9001-9010'/- '$SHMEXT:$SHMEXT'/" docker-compose.yml
  sed -i '' "s/- '10001-10010:10001-10010'/- '$SHMINT:$SHMINT'/" docker-compose.yml
else
  sed "s/- '8080:8080'/- '$DASHPORT:$DASHPORT'/" docker-compose.tmpl > docker-compose.yml
  sed -i "s/- '9001-9010:9001-9010'/- '$SHMEXT:$SHMEXT'/" docker-compose.yml
  sed -i "s/- '10001-10010:10001-10010'/- '$SHMINT:$SHMINT'/" docker-compose.yml
fi

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

docker-compose-safe -f docker-compose.yml up -d > /dev/null 2>&1 || { echo "Error: Docker startup failed. Exiting."; exit 1; }


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

# Secrets.json check and actions
cd ${CURRENT_DIRECTORY}
if [ -f secrets.json ]; then
  echo "Reusing old node"
  CONTAINER_ID=$(docker-safe ps -qf "ancestor=local-dashboard")
  docker-safe cp ./secrets.json "${CONTAINER_ID}:/home/node/app/cli/build/secrets.json" > /dev/null 2>&1 || { echo "Error: Failed to copy secrets.json to container. Exiting."; exit 1; }
  rm -f secrets.json
fi

IP_ADDRESS=$(wget -qO- eth0.me)
if docker ps | grep "shardeum-dashboard" | grep -q "0.0.0.0:8080->8080/tcp"; then
DASHBOARD_ADDRESS="https://$IP_ADDRESS:8080"
fi

# Final instructions
if [ $RUNDASHBOARD = "y" ]
then
cat <<EOF
  ┌───────────────────────────────────────────────────────────────┐
  │                     Web Dashboard Usage                       │
  ├───────────────────────────────────────────────────────────────┤
  │ 1. Note the IP address used to connect to the node. It could  │
  │    be an external IP, LAN IP, or localhost.                   │
  │ 2. Open a browser & navigate to:                              │
  │    $DASHBOARD_ADDRESS                                   │
  │ 3. Go to the Settings tab & connect a wallet.                 │
  │ 4. Visit the Maintenance tab & click the Start Node button.   │
  ├───────────────────────────────────────────────────────────────┤
  │ NOTE: If this validator is on the cloud and accessed over the │
  │ internet, set a strong password and use the external IP.      │
  └───────────────────────────────────────────────────────────────┘
EOF

cat <<EOF
  ┌───────────────────────────────────────────────────────────────┐
  │                Command Line Interface Usage                   │
  ├───────────────────────────────────────────────────────────────┤
  │ 1. Navigate to the Shardeum directory ($NODEHOME).│
  │ 2. Enter the validator container with ./shell.sh.             │
  │ 3. Run "operator-cli --help" for commands.                    │
  └───────────────────────────────────────────────────────────────┘
EOF
fi
SCRIPT_EXECUTED=true
if [ "$SCRIPT_EXECUTED" != true ]; then
    exit 1
fi