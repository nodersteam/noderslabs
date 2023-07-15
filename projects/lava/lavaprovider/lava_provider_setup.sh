#!/bin/bash

wallet_operations() {
  echo "Wallet operations..."
  wallet_list=$(lavad keys list show --keyring-backend test)
  if [[ $wallet_list == "[]" ]]; then
    read -p "Wallet not found. Would you like to create a new one or recover an old one? (new/recover) " wallet_choice
    case $wallet_choice in
      new)
        read -p "Enter a name for the new wallet: " wallet_name
        lavad keys add $wallet_name --keyring-backend test
        echo "IMPORTANT: Remember to save your mnemonic somewhere safe!"
        ;;
      recover)
        read -p "Enter a name for the recovered wallet: " wallet_name
        lavad keys add $wallet_name --recover --keyring-backend test
        ;;
      *)
        echo "Invalid option."
        exit 1
        ;;
    esac
  else
    echo "Existing wallets:"
    echo "$wallet_list" | grep -e 'name:' -e 'address:' | sed -e "s/- name: \(.*\)/Name: \1/" -e 's/  address: /Wallet address: /'
    read -p "Do you want to use an existing wallet or create/recover another one? (use/create/recover) " wallet_operation
    case $wallet_operation in
      use)
        read -p "Enter your wallet name: " wallet_name
        ;;
      create)
        read -p "Enter a name for the new wallet: " wallet_name
        lavad keys add $wallet_name --keyring-backend test
        echo "IMPORTANT: Remember to save your mnemonic somewhere safe!"
        ;;
      recover)
        read -p "Enter a name for the recovered wallet: " wallet_name
        lavad keys add $wallet_name --recover --keyring-backend test
        ;;
      *)
        echo "Invalid option."
        exit 1
        ;;
    esac
  fi

  echo "To continue, make sure at least 0.1 LAVA has been requested or sent to your address. Otherwise, you won't be able to check the balance because the address isn't registered on the network."
  read -p "Do you wish to continue? (yes/no) " confirmation
  if [[ $confirmation == "yes" ]]; then
    balance_output=$(lavad q bank balances $(lavad keys show $wallet_name --keyring-backend test -a) --node https://lava-testnet.rpc.kjnodes.com:443 2>&1)
    if [[ $balance_output == *"Error"* ]]; then
      echo "Error occurred while checking the balance. Please try again later or contact the network administrator."
      exit 1
    fi
    echo "$balance_output" > balance.txt
    balance_ulava=$(cat balance.txt | grep "amount:" | cut -d '"' -f2)
    if [[ -n $balance_ulava && $balance_ulava -ne 0 ]]; then
      balance_lava=$(echo "scale=6; $balance_ulava / 1000000" | bc)
      # Check if the balance starts with a dot
      if [[ ${balance_lava:0:1} == "." ]]; then
        # Prepend a 0 if the balance starts with a dot
        balance_lava="0$balance_lava"
      fi
      if [ $(echo "$balance_lava < 50000" | bc) -eq 1 ]; then
        echo "Your balance is less than required 50000 Lava. Current balance: $balance_lava LAVA"
      else
        echo "Your balance meets the requirement 50000 Lava. Current balance: $balance_lava LAVA"
      fi
    else
      echo "Your balance is zero or cannot be determined."
    fi
  else
    echo "Operation cancelled by the user."
  fi
}

install_go() {
  read -p "Enter version of Go to install (format X.Y.Z): " ver
  cd $HOME
  wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" >/dev/null 2>&1
  sudo rm -rf /usr/local/go >/dev/null 2>&1
  sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" >/dev/null 2>&1
  rm "go$ver.linux-amd64.tar.gz" >/dev/null 2>&1
  echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
  source ~/.bash_profile
  echo "Go version $ver installed successfully!"
}

install_and_check() {
  local total=${#packages[@]}
  local count=0

  for package in "${packages[@]}"; do
    echo -n "Installing $package... "
    if sudo apt-get install -y "$package" >/dev/null 2>&1; then
      ((count++))
      echo "done. ($((100 * count / total))% completed)"
    else
      echo "FAILED"
      exit 1
    fi
  done

  echo "All packages installed successfully!"
}

prepare_server() {
  echo "Preparing server for installation..."
  sudo apt-get update -y >/dev/null
  sudo apt-get upgrade -y >/dev/null
  install_and_check
  install_go
}

install_lava() {
  echo "Installing Lava..."
  git clone https://github.com/lavanet/lava.git >/dev/null 2>&1
  cd lava
  latest_tags=$(git tag -l --sort=-v:refname | head -n 3)
  echo "Latest tags:"
  echo "$latest_tags"
  read -p "Enter the tag to install: " selected_tag

  if echo "$latest_tags" | grep -qw "$selected_tag"; then
    git checkout "$selected_tag" >/dev/null 2>&1
    make install >/dev/null 2>&1
    lavad config chain-id lava-testnet-1
    lavad config keyring-backend test
    lavad_version=$(lavad version)
    echo "Lava installed successfully!"
    echo "Installed Lava version: ${lavad_version#*v}"
    cd $HOME
  fi
}


install_lava_provider() {
  echo "Before proceeding with the Lava Provider installation, you need to customize the URL that will be used to access the provider."
  echo "This is required to configure a domain name or IP address that will point to the provider."
  echo ""
  echo "Example of a customized URL: lava-provider.nodersteam.com"
  echo ""
  echo "In the above example, 'lava-provider' represents the domain name or IP address that you can choose according to your preferences."
  echo "Please make sure that you have set up the DNS records or configured the IP address correctly for the specified domain name."
  echo ""

  read -p "Enter the wallet name: " wallet_name
  read -p "Enter the customized URL for the provider (e.g., lava-provider.nodersteam.com): " provider_url

  config_file="$HOME/.lava/config/provider.yml"

  # Создаем папку .lava/config, если она не существует
  mkdir -p "$(dirname "$config_file")"

  # Проверяем, существует ли файл конфигурации
  if [ -f "$config_file" ]; then
    echo "Existing projects in the configuration file:"
    existing_projects=$(grep -Po '(?<=# )\S+' "$config_file" | sort -u)
    echo "$existing_projects"
    echo ""
  else
    echo "No existing projects found in the configuration file."
    echo ""
    existing_projects=""
    echo "endpoints:" >> "$config_file"
  fi

  project_count=0
  while true; do
    read -p "Enter the project name (leave empty to finish): " project_name
    if [ -z "$project_name" ]; then
      break
    fi

    # Проверяем, существует ли уже указанный проект в конфигурации
    if echo "$existing_projects" | grep -qw "$project_name"; then
      echo "Project '$project_name' is already present in the configuration. Skipping..."
      echo ""
      continue
    fi

    read -p "Enter the amount of tokens to stake in the provider for project '$project_name': " stake_amount
    read -p "Enter the provider port for project '$project_name': " provider_port
    read -p "Enter the provider's moniker for project '$project_name': " provider_moniker

    # Запрашиваем количество URL для каждого интерфейса
    read -p "Enter the number of JSON-RPC URLs for project '$project_name': " jsonrpc_count
    read -p "Enter the number of Tendermint RPC URLs for project '$project_name': " tendermintrpc_count
    read -p "Enter the number of gRPC URLs for project '$project_name': " grpc_count
    read -p "Enter the number of REST URLs for project '$project_name': " rest_count

    # Добавляем информацию о проекте в файл конфигурации
    echo "" >> "$config_file"
    echo "# $project_name" >> "$config_file"
    echo "  - api-interface: jsonrpc" >> "$config_file"
    echo "    chain-id: $project_name" >> "$config_file"
    echo "    network-address: 0.0.0.0:$provider_port" >> "$config_file"
    echo "    node-urls:" >> "$config_file"

    for ((i=1; i<=jsonrpc_count; i++)); do
      read -p "Enter the JSON-RPC URL #$i for project '$project_name': " jsonrpc_url
      echo "      - url: $jsonrpc_url" >> "$config_file"
      echo "        timeout: 5s" >> "$config_file"
    done

    echo "  - api-interface: tendermintrpc" >> "$config_file"
    echo "    chain-id: $project_name" >> "$config_file"
    echo "    network-address: 0.0.0.0:$provider_port" >> "$config_file"
    echo "    node-urls:" >> "$config_file"

    for ((i=1; i<=tendermintrpc_count; i++)); do
      read -p "Enter the Tendermint RPC URL #$i for project '$project_name': " tendermintrpc_url
      echo "      - url: $tendermintrpc_url" >> "$config_file"
      echo "        timeout: 5s" >> "$config_file"
    done

    echo "  - api-interface: grpc" >> "$config_file"
    echo "    chain-id: $project_name" >> "$config_file"
    echo "    network-address: 0.0.0.0:$provider_port" >> "$config_file"
    echo "    node-urls:" >> "$config_file"

    for ((i=1; i<=grpc_count; i++)); do
      read -p "Enter the gRPC URL #$i for project '$project_name': " grpc_url
      echo "      - url: $grpc_url" >> "$config_file"
      echo "        timeout: 5s" >> "$config_file"
    done

    echo "  - api-interface: rest" >> "$config_file"
    echo "    chain-id: $project_name" >> "$config_file"
    echo "    network-address: 0.0.0.0:$provider_port" >> "$config_file"
    echo "    node-urls:" >> "$config_file"

    for ((i=1; i<=rest_count; i++)); do
      read -p "Enter the REST URL #$i for project '$project_name': " rest_url
      echo "      - url: $rest_url" >> "$config_file"
      echo "        timeout: 5s" >> "$config_file"
    done

    echo "" >> "$config_file"

    echo "Added project '$project_name' to the configuration file."
    echo ""
    existing_projects+="$project_name\n"
    ((project_count++))
  done

  if [ "$project_count" -eq 0 ]; then
    echo "No new projects added to the configuration file."
  else
    echo "Added a total of $project_count new project(s) to the configuration file."
  fi

  echo ""
  echo "The Lava Provider has been successfully configured!"
  echo "Wallet name: $wallet_name"
  echo "Provider URL: $provider_url"
  echo "Configuration file: $config_file"
  
# Запрашиваем у пользователя, хочет ли он выполнить стейкинг
read -p "Do you want to stake the provider? (Y/N): " stake_choice

if [ "$stake_choice" = "Y" ] || [ "$stake_choice" = "y" ]; then
  # Запрашиваем название проекта для стейкинга
  read -p "Enter the project name for staking the provider: " project_name

  # Проверяем, что название проекта не пустое
  if [ -z "$project_name" ]; then
    echo "Project name cannot be empty. Staking aborted."
    exit 1
  fi

  # Выполняем команду для стейкинга провайдера
  echo ""
  echo "Staking the provider..."
  lavad tx pairing stake-provider "$project_name" "${stake_amount}ulava" "${provider_url}:${provider_port},jsonrpc,2 ${provider_url}:${provider_port},grpc,2 ${provider_url}:${provider_port},tendermintrpc,2 ${provider_url}:${provider_port},rest,2" 2 --from "$wallet_name" --provider-moniker "$provider_moniker" --keyring-backend "test" --chain-id "lava-testnet-1" --gas="auto" --gas-adjustment "1.5" --node https://lava-testnet.rpc.kjnodes.com:443
else
  echo "Skipping staking the provider."
fi

# Проверяем, существует ли файл сервиса
if [ -f "/etc/systemd/system/lava-provider.service" ]; then
  echo "The 'lava-provider' service already exists."
  echo "You can start, stop, or restart the service using the following commands:"
  echo "sudo systemctl start lava-provider"
  echo "sudo systemctl stop lava-provider"
  echo "sudo systemctl restart lava-provider"
  echo "For check logs using the following command"
  echo "sudo journalctl -u lava-provider -f"
else
  # Создаем файл сервиса
  sudo tee /etc/systemd/system/lava-provider.service > /dev/null <<EOT
[Unit]
Description=Lava Provider
After=network-online.target

[Service]
User=$USER
ExecStart=$HOME/go/bin/lavad rpcprovider $HOME/.lava/config/provider.yml --geolocation 2 --from $wallet_name --keyring-backend test --node https://lava-testnet.rpc.kjnodes.com:443
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOT

  # Перезапускаем демона systemd, чтобы он обнаружил новый сервис
  sudo systemctl daemon-reload

  # Включаем и запускаем сервис
  sudo systemctl enable lava-provider
  sudo systemctl start lava-provider
  echo "You can start, stop, or restart the service using the following commands:"
  echo "sudo systemctl start lava-provider"
  echo "sudo systemctl stop lava-provider"
  echo "sudo systemctl restart lava-provider"
  echo "For check logs using the following command"
  echo "sudo journalctl -u lava-provider -f"
  echo "The 'lava-provider' service has been created and started."
fi

}

update_lava() {
  echo "Updating Lava..."
  cd lava
  git fetch >/dev/null 2>&1
  latest_tags=$(git tag -l --sort=-v:refname | head -n 3)
  echo "Latest tags:"
  echo "$latest_tags"
  read -p "Enter the tag to update to: " selected_tag

  if echo "$latest_tags" | grep -qw "$selected_tag"; then
    git checkout "$selected_tag" >/dev/null 2>&1
    make install >/dev/null 2>&1
    lavad config chain-id lava-testnet-1
    lavad config keyring-backend test
    lavad_version=$(lavad version)
    echo "Lava updated successfully!"
    echo "Installed Lava version: ${lavad_version#*v}"

  fi
}

check_provider() {
  # Проверяем статус сервиса lava-provider
  sudo systemctl is-active --quiet lava-provider
  local is_active=$?

  if [ $is_active -eq 0 ]; then
    echo "The lava-provider service is active."
    echo ""

    # Выполняем команду для проверки работы провайдера
    echo "Running the 'lavad test rpcprovider' command..."
    lavad test rpcprovider --from "$wallet_name" --node https://lava-testnet.rpc.kjnodes.com:443
  else
    echo "The lava-provider service is not active."
    echo "Please make sure that the service is running correctly."
  fi
}



show_menu() {
  echo "1) Prepare server for installation"
  echo "2) Install Lava"
  echo "3) Wallet operations"
  echo "4) Install Lava Provider"
  echo "5) Check provider"
  echo "6) Update Lava"
  echo "7) Exit"
}

packages=(curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool)

while true
do
  show_menu
  read CHOICE
  case $CHOICE in
    1) prepare_server;;
    2) install_lava;;
    3) wallet_operations;;
    4) install_lava_provider;;
    5) check_provider;;
    6) update_lava;;
    7) break;;
    *) echo "Invalid option.";;
  esac
  echo ""
done
