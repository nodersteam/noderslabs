#!/bin/bash

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check and install curl if necessary
if command_exists curl; then
  echo "Curl is already installed"
else
  sudo apt-get update && sudo apt-get install curl -y
fi

# Check and install jq if necessary
if command_exists jq; then
  echo "jq is already installed"
else
  sudo apt-get update && sudo apt-get install jq -y
fi

# Load bash profile
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi

# Get latest tag from GitHub releases
get_latest_tag() {
  curl --silent "https://api.github.com/repos/nymtech/nym/releases" |
  jq -r '.[] | select(.name | test("Nym Binaries")) | .tag_name' |
  head -1
}

# Node setup
setup_node() {
  # Enter node name if it doesn't exist
  if [ ! $node_name ]; then
    read -p "Enter node name: " node_name
    echo 'export node_name='\"${node_name}\" >> $HOME/.bash_profile
  fi

  # Source bash profile
  echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
  . $HOME/.bash_profile

  # Echo node name
  echo 'Your node name: ' $node_name

  # Update system
  sudo apt-get update

  # Install necessary packages
  sudo apt-get install -y ufw make clang pkg-config libssl-dev build-essential git 

  # Install rust
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source $HOME/.cargo/env
  rustup update

  # Remove old directory and clone new one
  cd $HOME
  rm -rf nym
  git clone https://github.com/nymtech/nym.git

  # Build and move binary
  cd nym
  latest_tag=$(get_latest_tag)
  git checkout "$latest_tag"
  cargo build --release --bin nym-mixnode
  sudo mv target/release/nym-mixnode /usr/local/bin/

  # Initialize node
  nym-mixnode init --id $node_name --host $(curl ipinfo.io/ip)

  # Configure firewall
  sudo ufw allow 1789,1790,8000,22,80,443/tcp

  # Configure service
  sudo bash -c "cat > /etc/systemd/system/nym-mixnode.service" <<EOF
[Unit]
Description=Nym Mixnode

[Service]
User=$USER
ExecStart=/usr/local/bin/nym-mixnode run --id '$node_name'
KillSignal=SIGINT
Restart=on-failure
RestartSec=30
StartLimitInterval=350
StartLimitBurst=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable nym-mixnode
  sudo systemctl restart nym-mixnode
  echo "Congrats! Your mixnode is running. It's time to delegate tokens on it and promote it among your friends."
  echo "Support and embrace the privacy provided by NYM"
}

# Node update
update_node() {
  echo "Fetching the latest version info from GitHub..."
  latest_tag=$(get_latest_tag)

  echo "Latest version is $latest_tag. Do you want to update to this version? [Y/n]"
  read -r answer

  case ${answer:0:1} in
    y|Y )
        echo "Updating to version $latest_tag..."
        cd $HOME/nym
        git fetch
        git checkout "$latest_tag"
        cargo build --release --bin nym-mixnode
        sudo mv target/release/nym-mixnode /usr/local/bin/nym-mixnode
        sudo systemctl restart nym-mixnode
    ;;
    * )
        echo "Update cancelled."
    ;;
  esac
}

# Node status check
check_status() {
  node_status=$(sudo systemctl is-active nym-mixnode)
  if [ "$node_status" = "active" ]; then
    echo "Nym Mixnode service is active and running."
  else
    echo "Nym Mixnode service is inactive."
  fi
}

# Node removal
remove_node() {
  sudo systemctl stop nym-mixnode
  sudo systemctl disable nym-mixnode
  sudo rm /usr/local/bin/nym-mixnode
  sudo rm /etc/systemd/system/nym-mixnode.service
  sudo systemctl daemon-reload
  rm -rf $HOME/nym
  echo "Nym node removed successfully."
}

# Node actions menu
while true; do
  PS3='Please enter your choice: '
  options=("Setup Node" "Check Node" "Update Node" "Remove Node" "Quit")
  select opt in "${options[@]}"
  do
      case $opt in
          "Setup Node")
              setup_node
              break
              ;;
          "Check Node")
              check_status
              break
              ;;
          "Update Node")
              update_node
              break
              ;;
          "Remove Node")
              remove_node
              break
              ;;
          "Quit")
              break 2
              ;;
          *) echo "invalid option $REPLY";;
      esac
  done
done
