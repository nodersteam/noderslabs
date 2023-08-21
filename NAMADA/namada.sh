#!/bin/bash
clear

# Check bash
if [[ ! -f "$HOME/.bash_profile" ]]; then
    touch "$HOME/.bash_profile"
fi

if [ -f "$HOME/.bash_profile" ]; then
    source $HOME/.bash_profile
fi

cat << "EOF"
___      ___       _     ___       ___      _     ________        _      
`MM\     `M'      dM.    `MMb     dMM'     dM.    `MMMMMMMb.     dM.     
 MMM\     M      ,MMb     MMM.   ,PMM     ,MMb     MM    `Mb    ,MMb     
 M\MM\    M      d'YM.    M`Mb   d'MM     d'YM.    MM     MM    d'YM.    
 M \MM\   M     ,P `Mb    M YM. ,P MM    ,P `Mb    MM     MM   ,P `Mb    
 M  \MM\  M     d'  YM.   M `Mb d' MM    d'  YM.   MM     MM   d'  YM.   
 M   \MM\ M    ,P   `Mb   M  YM.P  MM   ,P   `Mb   MM     MM  ,P   `Mb   
 M    \MM\M    d'    YM.  M  `Mb'  MM   d'    YM.  MM     MM  d'    YM.  
 M     \MMM   ,MMMMMMMMb  M   YP   MM  ,MMMMMMMMb  MM     MM ,MMMMMMMMb  
 M      \MM   d'      YM. M   `'   MM  d'      YM. MM    .M9 d'      YM. 
_M_      \M _dM_     _dMM_M_      _MM_dM_     _dMM_MMMMMMM9_dM_     _dMM_

Smart script for NAMADA node
Developed by [NODERS]TEAM

EOF

max_label_width=20

print_variable() {
    local label=$1
    local value=$2
    printf "%-${max_label_width}s %s\n" "$label:" "$value"
}

RED="\033[1;31m"
GREEN="\033[1;32m"
RESET="\033[0m"

print_variable() {
    local label=$1
    local value=$2

    # If NOT_SET = Red, Else = Green
    if [[ "$value" == "NOT SET" ]]; then
        printf "%-20s %b%s%b\n" "$label:" $RED "$value" $RESET
    else
        printf "%-20s %b%s%b\n" "$label:" $GREEN "$value" $RESET
    fi
}

# UPDATE SERVICE_STATUS
if grep -q '^export SERVICE_STATUS=' $HOME/.bash_profile; then
    sed -i '/export SERVICE_STATUS=/d' $HOME/.bash_profile
fi
SERVICE_STATUS=$(sudo systemctl is-active namadad.service)
echo "export SERVICE_STATUS=$SERVICE_STATUS" >> $HOME/.bash_profile

# UPDATE SYNC_STATUS
if grep -q '^export SYNC_STATUS=' $HOME/.bash_profile; then
    sed -i '/export SYNC_STATUS=/d' $HOME/.bash_profile
fi
SYNC_STATUS=$(curl -s localhost:26657/status | jq -r '.result.sync_info.catching_up')
echo "export SYNC_STATUS=$SYNC_STATUS" >> $HOME/.bash_profile

# UPDATE NODE_BLOCK_HEIGHT
if grep -q '^export NODE_BLOCK_HEIGHT=' $HOME/.bash_profile; then
    sed -i '/export NODE_BLOCK_HEIGHT=/d' $HOME/.bash_profile
fi
NODE_BLOCK_HEIGHT=$(curl -s localhost:26657/status | jq -r '.result.sync_info.latest_block_height')
echo "export NODE_BLOCK_HEIGHT=$NODE_BLOCK_HEIGHT" >> $HOME/.bash_profile



if [[ ! -z "$MONIKER" ]]; then
    print_variable "Validator moniker" "$MONIKER"
    print_variable "Validator address" "${VALIDATOR_ADDRES:-NOT SET}"
    
    if [[ ! -z "$VALIDATOR_ADDRES" ]]; then
        balance_output_validator=$(namada client balance --owner $MONIKER --token NAM)
        VALIDATOR_BALANCE=$(echo $balance_output_validator | awk '{print $2}')

        if [[ $VALIDATOR_BALANCE =~ ^[0-9.]+$ ]]; then
            if (( $(echo "$VALIDATOR_BALANCE > 0" | bc -l) )); then
                echo "Validator balance:   $VALIDATOR_BALANCE NAM"
            else
                echo "Validator balance:   0 NAM"
            fi
        else
            echo "Validator balance:   0 NAM"
        fi
    fi
    
    echo ""
    print_variable "Wallet name" "${WALLET_NAME:-NOT SET}"
    print_variable "Wallet address" "${WALLET_ADDRES:-NOT SET}"

    if [[ "$SYNC_STATUS" == "false" ]]; then
        balance_output_wallet=$(namada client balance --owner $WALLET_NAME --token NAM)
        WALLET_BALANCE=$(echo $balance_output_wallet | awk '{print $2}')

        if [[ $WALLET_BALANCE =~ ^[0-9.]+$ ]]; then
            echo "Wallet balance:      $WALLET_BALANCE NAM"
        else
            echo "Wallet balance:      0 NAM"
        fi
    fi

    if [[ ! -z "$WALLET_NAME" ]]; then
        staking_output=$(namada client bonds --owner $MONIKER)
        LAST_COMMITTED_EPOCH=$(echo "$staking_output" | awk '/Last committed epoch:/ {print $4}')
        VALIDATOR_BOND=$(echo "$staking_output" | awk '/All bonds total:/ {print $4}')
    fi
    print_variable "Validator bond" "${VALIDATOR_BOND:-NOT SET}"
    echo ""
    print_variable "Node block height" "$NODE_BLOCK_HEIGHT"
    
    if [[ "$SYNC_STATUS" == "true" ]]; then
        echo -e "Sync status:         \e[31mIn progress\e[0m"  # RED
    else
        echo -e "Sync status:         \e[32mSynced\e[0m"  # GREEN
    fi
    
    if [[ "$SERVICE_STATUS" == "active" ]]; then
        echo -e "Service status:      \e[32mACTIVE\e[0m"  # GREEN
    else
        echo -e "Service status:      \e[31mNOT ACTIVE\e[0m"  # RED
    fi
    
    echo "                                                                         "
fi

sleep 2

while true; do
    echo "                                                                         "
    echo "================== Namada Node Installation Menu ========================"
    echo "                                                                         "
    echo "1. Node (Install, Uninstall, Restart)"
    echo "2. Node Status Check (Logs, Error Journal, Service Status)"
    echo "3. Validator (Check Balance, Init validator, Check Staking, Delegate (From wallet and validator address)"
    echo "4. Faucet (Request Tokens)"
    echo "5. Exit"
    echo "                                                                         "
    echo "========================================================================="
    read -p "Please enter the number corresponding to your choice: " main_choice

    case $main_choice in
        1)
            echo "                                                                  "
            echo "1. Install Node"
            echo "2. Uninstall Node"
            echo "3. Restart Node"
            echo "4. Return to Main Menu"
            read -p "Enter your choice: " node_choice
            case $node_choice in
                1) 
                    echo "Installing Node..."
                    
                    
                    installNode() {
    echo "======================== Node Installation ==============================="

    # User set Moniker
    read -p "Set Validator Moniker: " input_moniker
    if [ -z "$input_moniker" ]; then
        echo "Moniker cannot be empty!"
        return
    fi
    
    MONIKER=$input_moniker
    echo "Moniker set to: $MONIKER"
    
    # User set Wallet
    read -p "Set wallet name: " input_wallet_name
    if [ -z "$input_wallet_name" ]; then
        echo "Wallet name cannot be empty!"
        return
    fi
    
    WALLET_NAME=$input_wallet_name
    echo "Wallet name set to: $WALLET_NAME"

    # User set CHAIN_ID
    echo "Would you like to use the default Chain ID 'public-testnet-12.fedec12f3428'? (y/n)"
    read choice

    if [[ $choice == "y" || $choice == "Y" ]]; then
        CHAIN_ID="public-testnet-12.fedec12f3428"
    else
    echo "Please enter the name of Chain ID:"
    read CHAIN_ID
    fi

echo "Selected network: $CHAIN_ID"

    # Set var in profile
    sed -i "/MONIKER=/d" $HOME/.bash_profile
    sed -i "/CHAIN_ID=/d" $HOME/.bash_profile
    sed -i "/WALLET_NAME=/d" $HOME/.bash_profile
    echo "export MONIKER=$MONIKER" >> $HOME/.bash_profile
    echo "export CHAIN_ID=$CHAIN_ID" >> $HOME/.bash_profile
    echo "export WALLET_NAME=$WALLET_NAME" >> $HOME/.bash_profile

    # Res profile
    source $HOME/.bash_profile

    # Start installing
    echo "Starting installation..."

    # Install dependience
    echo "Installing main dependencies..."
    sudo apt update &>/dev/null
    sudo apt upgrade -y &>/dev/null
    sudo apt install curl tar wget clang pkg-config git make libssl-dev libclang-dev libclang-12-dev jq build-essential bsdmainutils ncdu gcc git-core chrony liblz4-tool uidmap dbus-user-session protobuf-compiler unzip -y &>/dev/null

   echo "Installing Rust and Node.js..."

    # Rust
    curl -sSf https://sh.rustup.rs | sh -s -- -y &>/dev/null
    . $HOME/.cargo/env

    # Node.js
    curl -sSf https://deb.nodesource.com/setup_18.x | sudo bash &>/dev/null
    sudo apt install cargo nodejs -y < "/dev/null" &>/dev/null
    
    echo " "
    echo "Installed Cargo version: $(cargo --version)"
    echo "Installed Node version: $(node -v)"
    echo " "

    # Go
    if ! [ -x "$(command -v go)" ]; then
        echo "Installing Go..."
        ver="1.19.4"
        cd $HOME && wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" &>/dev/null
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" &>/dev/null
        rm "go$ver.linux-amd64.tar.gz"
        echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
        source ~/.bash_profile
        echo " "
        echo "Installed Go version: $(go version)"
        echo " "
    fi

    # Update Rust and inst Protoc
    echo "Updating Rust and installing Protoc..."
    cd $HOME && rustup update &>/dev/null
    PROTOC_ZIP=protoc-23.3-linux-x86_64.zip
    curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v23.3/$PROTOC_ZIP &>/dev/null
    sudo unzip -o $PROTOC_ZIP -d /usr/local bin/protoc &>/dev/null
    sudo unzip -o $PROTOC_ZIP -d /usr/local 'include/*' &>/dev/null
    rm -f $PROTOC_ZIP
    echo "Installed Protoc version: $(protoc --version)"

    # Set var
    echo "Configuring environment variables..."
    sed -i '/public-testnet/d' "$HOME/.bash_profile"
    sed -i '/NAMADA_TAG/d' "$HOME/.bash_profile"
    sed -i '/WALLET_ADDRESS/d' "$HOME/.bash_profile"
    sed -i '/CBFT/d' "$HOME/.bash_profile"
    echo "export NAMADA_TAG=$(curl -s https://api.github.com/repos/anoma/namada/releases/latest | jq -r .tag_name)" >> ~/.bash_profile
    echo "export CBFT=v0.37.2" >> ~/.bash_profile
    echo "export BASE_DIR=$HOME/.local/share/namada" >> ~/.bash_profile
    
    # Clone and build Namada
    sleep 2
    echo "Cloning and building namada..."
    cd $HOME && git clone https://github.com/anoma/namada &>/dev/null && cd namada && git checkout $NAMADA_TAG &>/dev/null
    make build-release

    # Clone and build cometbft
    sleep 2
    echo "Cloning and building cometbft..."
    cd $HOME && git clone https://github.com/cometbft/cometbft.git &>/dev/null && cd cometbft
    git checkout v0.37.2 &>/dev/null  # Check out the specific version
    make build

    # Check and set dir
    if [ ! -d "/usr/local/bin" ]; then
        sudo mkdir -p /usr/local/bin
    fi
    
    # Mv bin file
    sleep 2
    echo "Copying binaries..."
    cp "$HOME/cometbft/build/cometbft" /usr/local/bin/cometbft &>/dev/null
    cp "$HOME/namada/target/release/namada" /usr/local/bin/namada &>/dev/null
    cp "$HOME/namada/target/release/namadac" /usr/local/bin/namadac &>/dev/null
    cp "$HOME/namada/target/release/namadan" /usr/local/bin/namadan &>/dev/null
    cp "$HOME/namada/target/release/namadaw" /usr/local/bin/namadaw &>/dev/null
    
    # Check ver
    cometbft_version=$(cometbft version)
    namada_version=$(namada --version)
    echo "Installed cometbft version: $cometbft_version"
    echo "Installed namada version: $namada_version"
    cd $HOME
    # Set service
    if [ ! -f "/etc/systemd/system/namadad.service" ]; then
        echo "Creating service file..."
        sudo tee /etc/systemd/system/namadad.service > /dev/null <<EOF
[Unit]
Description=namada
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/.local/share/namada
Environment=TM_LOG_LEVEL=p2p:none,pex:error
Environment=NAMADA_CMT_STDOUT=true
ExecStart=/usr/local/bin/namada node ledger run 
StandardOutput=syslog
StandardError=syslog
Restart=always
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl daemon-reload &>/dev/null
        sudo systemctl enable namadad &>/dev/null
        
        
        echo "Service file successfully created and enabled!"
    else
        echo "Service file namadad.service already exists. Proceeding to the next step."
    fi
    
     # Join in network
    echo "Joining the network..."
    cd $HOME && namada client utils join-network --chain-id $CHAIN_ID

    # Start namadad
    echo "Starting namadad service..."
    sudo systemctl start namadad

# Check status
sed -i '/export SERVICE_STATUS=/d' $HOME/.bash_profile
SERVICE_STATUS=$(sudo systemctl is-active namadad.service)
echo "export SERVICE_STATUS=$SERVICE_STATUS" >> $HOME/.bash_profile

if [[ "$SERVICE_STATUS" == "active" ]]; then
    echo "Service status: Active"
else
    echo "Service status: Inactive"
fi

# Must get info for cont
while [[ "$SERVICE_STATUS" != "active" ]]; do
    sleep 5
    SERVICE_STATUS=$(sudo systemctl is-active namadad.service)
done

# Sync check
sed -i '/export SYNC_STATUS=/d' $HOME/.bash_profile
SYNC_STATUS=$(curl -s localhost:26657/status | jq -r '.result.sync_info.catching_up')
echo "export SYNC_STATUS=$SYNC_STATUS" >> $HOME/.bash_profile

# Must get info for cont
while [[ "$SYNC_STATUS" != "true" ]]; do
    sleep 5
    SYNC_STATUS=$(curl -s localhost:26657/status | jq -r '.result.sync_info.catching_up')
done
# Check color info
if [[ "$SYNC_STATUS" == "true" ]]; then
    echo -e "Sync status: \e[31mIn progress\e[0m"  # RED
else
    echo -e "Sync status: \e[32mSynced\e[0m"  # GREEN
fi

# Check block
sed -i '/export NODE_BLOCK_HEIGHT=/d' $HOME/.bash_profile
NODE_BLOCK_HEIGHT=$(curl -s localhost:26657/status | jq -r '.result.sync_info.latest_block_height')
echo "export NODE_BLOCK_HEIGHT=$NODE_BLOCK_HEIGHT" >> $HOME/.bash_profile
echo "Block height: $NODE_BLOCK_HEIGHT"

namada wallet address gen --alias $WALLET_NAME --unsafe-dont-encrypt
    
    echo "Installation completed successfully!"
    echo " "
    echo "PLEASE NOTE!"
    echo "You can proceed with further actions after the node is fully synchronized."
    echo "Synchronization status you can check in the Node Status Check menu"
    
}

installNode
                    ;;
                2)
                    echo "Uninstalling Node..."
                    
                    uninstallNode() {
    echo "======================== Node Uinstallation =============================="


# Stop and disable service
sudo systemctl stop namadad &>/dev/null
sudo systemctl disable namadad &>/dev/null
sudo rm -rf $HOME/.local/share/namada

# Del service
sudo rm -f /etc/systemd/system/namadad.service

# Del dir
rm -rf ~/namada &>/dev/null
rm -rf ~/cometbft &>/dev/null

# Unset var from bash profile
if [[ -e $HOME/.bash_profile ]]; then
    sed -i '/MONIKER=/d' $HOME/.bash_profile &>/dev/null
    sed -i '/CHAIN_ID=/d' $HOME/.bash_profile &>/dev/null
    sed -i '/NAMADA_TAG=/d' $HOME/.bash_profile &>/dev/null
    sed -i '/CBFT=/d' $HOME/.bash_profile &>/dev/null
    sed -i '/WALLET_NAME=/d' $HOME/.bash_profile &>/dev/null
    sed -i '/SERVICE_STATUS=/d' $HOME/.bash_profile &>/dev/null
    sed -i '/NODE_BLOCK_HEIGHT=/d' $HOME/.bash_profile &>/dev/null
    sed -i '/VALIDATOR_BOND=/d' $HOME/.bash_profile &>/dev/null
    sed -i '/WALLET_BALANCE=/d' $HOME/.bash_profile &>/dev/null
    sed -i '/WALLET_ADDRES=/d' $HOME/.bash_profile &>/dev/null
    sed -i '/VALIDATOR_ADDRES=/d' $HOME/.bash_profile &>/dev/null
    sed -i '/SYNC_STATUS=/d' $HOME/.bash_profile &>/dev/null
    
fi

# Usnet var from session
unset MONIKER
unset CHAIN_ID
unset NAMADA_TAG
unset WALLET_NAME
unset CBFT
unset SERVICE_STATUS
unset NODE_BLOCK_HEIGHT
unset VALIDATOR_BOND
unset WALLET_BALANCE
unset WALLET_ADDRES
unset VALIDATOR_ADDRES
unset SYNC_STATUS

if [[ -e "/usr/local/bin/cometbft" || -e "/usr/local/bin/namada" || -e "/usr/local/bin/namadac" || -e "/usr/local/bin/namadan" || -e "/usr/local/bin/namadaw" ]]; then
    sudo rm -f /usr/local/bin/cometbft
    sudo rm -f /usr/local/bin/namada
    sudo rm -f /usr/local/bin/namadac
    sudo rm -f /usr/local/bin/namadan
    sudo rm -f /usr/local/bin/namadaw

    if [[ $? -eq 0 ]]; then
        echo "Uninstallation completed successfully!"
    else
        echo "There was an error during the uninstallation process!"
    fi
else
    echo "Node is not installed!"
fi
}

uninstallNode
                    ;;
               
                3)
                    echo "Restarting Node..."
                    restart_node() {
    echo "Restarting Node..."
    sudo systemctl restart namadad
    echo "Node successful restart"
}
restart_node
                    ;;
                4)
                    continue
                    ;;
                *)
                    echo "Invalid choice!"
                    ;;
            esac
            ;;
        2)
            
            echo "1. View Logs"
            echo "2. Error Journal"
            echo "3. Service Status"
            echo "4. Return to Main Menu"
            read -p "Enter your choice: " status_choice
            case $status_choice in
                1) 
                    view_logs() {
                    echo "Viewing Logs..."
                    sudo journalctl -u namadad --no-pager -n 100 --output cat
                }
                view_logs
                    ;;
                2)
                    view_error_journal() {
    echo "Viewing Error Journal..."
    echo "Parsing in progress..."
    
    logs=$(sudo journalctl -u namadad --no-pager | grep -E "error|warning" | tail -n 100)

    if [[ -n "$logs" ]]; then
        echo "$logs"
    else
        echo "No error or warning logs found."
    fi
}
                view_error_journal
                    ;;
                3)
                    view_service_status() {
    echo "Viewing Service Status..."

    if grep -q '^export SERVICE_STATUS=' $HOME/.bash_profile; then
        sed -i '/export SERVICE_STATUS=/d' $HOME/.bash_profile
    fi
    SERVICE_STATUS=$(sudo systemctl is-active namadad.service)
    echo "export SERVICE_STATUS=$SERVICE_STATUS" >> $HOME/.bash_profile

    if grep -q '^export SYNC_STATUS=' $HOME/.bash_profile; then
        sed -i '/export SYNC_STATUS=/d' $HOME/.bash_profile
    fi
    SYNC_STATUS=$(curl -s localhost:26657/status | jq -r '.result.sync_info.catching_up')
    echo "export SYNC_STATUS=$SYNC_STATUS" >> $HOME/.bash_profile

    if grep -q '^export NODE_BLOCK_HEIGHT=' $HOME/.bash_profile; then
        sed -i '/export NODE_BLOCK_HEIGHT=/d' $HOME/.bash_profile
    fi
    NODE_BLOCK_HEIGHT=$(curl -s localhost:26657/status | jq -r '.result.sync_info.latest_block_height')
    echo "export NODE_BLOCK_HEIGHT=$NODE_BLOCK_HEIGHT" >> $HOME/.bash_profile

    if [[ ! -z "$MONIKER" ]]; then
        print_variable "Validator moniker" "$MONIKER"
        print_variable "Address" "${VALIDATOR_ADDRESS:-NOT SET}"
        echo ""
        print_variable "Wallet name" "${WALLET_NAME:-NOT SET}"
        print_variable "Wallet address" "${WALLET_ADDRES:-NOT SET}"
        print_variable "Balance" "${WALLET_BALANCE:-NOT SET}"
        print_variable "Validator bond" "${VALIDATOR_BOND:-NOT SET}"
        echo ""
        print_variable "Node block height" "$NODE_BLOCK_HEIGHT"
        
        if [[ "$SYNC_STATUS" == "true" ]]; then
            echo -e "Sync status:         \e[31mIn progress\e[0m"  # RED
        else
            echo -e "Sync status:         \e[32mSynced\e[0m"  # GREEN
        fi
        
        if [[ "$SERVICE_STATUS" == "active" ]]; then
            echo -e "Service status:      \e[32mACTIVE\e[0m"  # GREEN
        else
            echo -e "Service status:      \e[31mNOT ACTIVE\e[0m"  # RED
        fi
        
        echo "                                                                         "
    fi
}
view_service_status
                    ;;
                4)
                    continue
                    ;;
                *)
                    echo "Invalid choice!"
                    ;;
            esac
            ;;
        3)
            
            echo "1. Check Balance"
            echo "2. Init validator"
            echo "3. Check Staking Status"
            echo "4. Delegate from Balance"
            echo "5. Return to Main Menu"
            read -p "Enter your choice: " validator_choice
            case $validator_choice in
                1) 
                    check_balance() {
    echo "Checking Balance..."
    balance_output=$(namada client balance --owner $WALLET_NAME --token NAM)
    WALLET_BALANCE=$(echo $balance_output | awk '{print $2}')
    echo "Wallet balance: $WALLET_BALANCE NAM"
}
check_balance
                    ;;
                2)
                    init_validator() {
    echo "Initing validator..."
    
    # Run the command to init the validator
    init_result=$(namada client init-validator \
        --alias $MONIKER \
        --account-keys $WALLET_NAME \
        --signing-keys $WALLET_NAME \
        --commission-rate 0.05 \
        --max-commission-rate-change 0.01)
    
    # Extract the validator address from the VPs result
    VALIDATOR_ADDRES=$(echo $init_result | grep -oE "atest1[0-9a-z]+" | tail -1)
    
    if [[ ! -z "$VALIDATOR_ADDRES" ]]; then
        # Save the validator address to VALIDATOR_ADDRESS variable
        sed -i '/export VALIDATOR_ADDRES=/d' $HOME/.bash_profile
        echo "export VALIDATOR_ADDRES=\"$VALIDATOR_ADDRES\"" >> $HOME/.bash_profile
        echo "Validator address initialized: $VALIDATOR_ADDRES"
    else
        echo "Failed to retrieve validator address. Initialization unsuccessful."
    fi
}
init_validator
                    ;;
                
                3)
                    echo "Checking Staking Status..."
                    check_staking_status() {
    echo "Checking Staking Status..."
    staking_output=$(namada client bonds --owner $WALLET_NAME)
    LAST_COMMITTED_EPOCH=$(echo "$staking_output" | awk '/Last committed epoch:/ {print $4}')
    VALIDATOR_BOND=$(echo "$staking_output" | awk '/All bonds total:/ {print $4}')
    
    if [[ ! -z "$VALIDATOR_BOND" ]]; then
        echo "Last committed epoch: $LAST_COMMITTED_EPOCH"
        echo "All bonds total: $VALIDATOR_BOND"
    else
        echo "Staking status information is not available"
    fi
}
check_staking_status
                    ;;
                4)
                    delegate_tokens() {
    if [[ ! -z "$MONIKER" ]]; then
        echo "1. Delegating from Wallet Address"
        echo "2. Delegating from Validator Address"
        read -p "Enter your choice: " delegation_choice
        
        if [[ $delegation_choice == "1" ]]; then
            print_variable "Wallet address" "$WALLET_ADDRES"
            print_variable "Wallet balance" "${WALLET_BALANCE:-NOT AVAILABLE}"
            
            if [[ "$SYNC_STATUS" == "false" ]]; then
                read -p "Enter the amount to delegate: " DELEGATION_AMOUNT
                
                if [[ $DELEGATION_AMOUNT =~ ^[0-9.]+$ ]]; then
                    namada client bond \
                      --source $WALLET_NAME \
                      --validator $MONIKER \
                      --amount $DELEGATION_AMOUNT
                else
                    echo "Invalid input. Delegation amount must be a positive number."
                fi
            else
                echo "Node synchronization is in progress. Delegation is not possible."
            fi
        elif [[ $delegation_choice == "2" ]]; then
            if [[ ! -z "$VALIDATOR_ADDRES" ]]; then
                print_variable "Validator address" "$VALIDATOR_ADDRES"
                print_variable "Validator balance" "${VALIDATOR_BALANCE:-NOT AVAILABLE}"
                
                if [[ "$SYNC_STATUS" == "false" ]]; then
                    read -p "Enter the amount to delegate: " DELEGATION_AMOUNT
                    
                    if [[ $DELEGATION_AMOUNT =~ ^[0-9.]+$ ]]; then
                        namada client bond \
                          --validator $MONIKER \
                          --amount $DELEGATION_AMOUNT
                    else
                        echo "Invalid input. Delegation amount must be a positive number."
                    fi
                else
                    echo "Node synchronization is in progress. Delegation is not possible."
                fi
            else
                echo "Validator address is not set. Delegation is not possible."
            fi
        else
            echo "Invalid choice!"
        fi
    else
        echo "Validator information is not available. Delegation is not possible."
    fi
}
delegate_tokens
;;

                5)
                    continue
                    ;;
                *)
                    echo "Invalid choice!"
                    ;;
            esac
            ;;
        4)
            
           request_tokens() {
    if [[ -z "$WALLET_ADDRES" ]]; then
        WALLET_ADDRESS=$(namadac balance --owner $WALLET_NAME --token NAM | grep "No nam balance found" | awk '{print $NF}')
        if [[ ! -z "$WALLET_ADDRES" ]]; then
            sed -i '/export WALLET_ADDRES=/d' $HOME/.bash_profile
            echo "export WALLET_ADDRES=\"$WALLET_ADDRESS\"" >> $HOME/.bash_profile
            source $HOME/.bash_profile
        fi
    fi
    
    echo "1. Request Tokens to Wallet Address ($WALLET_ADDRES)"
    
    if [[ ! -z "$VALIDATOR_ADDRES" ]]; then
        echo "2. Request Tokens to Validator Address ($VALIDATOR_ADDRES)"
    fi
    
    echo "3. Return to Main Menu"
    
    read -p "Enter your choice: " faucet_choice
    
    case $faucet_choice in
        1)
            echo "Requesting Tokens to Wallet Address ($WALLET_ADDRES)..."
            
            # Your token request script/code goes here
            namadac transfer \
                --token NAM \
                --amount 1000 \
                --source faucet \
                --target $WALLET_NAME \
                --signing-keys $WALLET_NAME
            
            echo "Tokens requested successfully!"
            ;;
        2)
            if [[ ! -z "$VALIDATOR_ADDRES" ]]; then
                echo "Requesting Tokens to Validator Address ($VALIDATOR_ADDRES)..."
                
                # Your token request script/code goes here
                namadac transfer \
                    --token NAM \
                    --amount 1000 \
                    --source faucet \
                    --target $MONIKER \
                    --signing-keys $WALLET_NAME
                
                echo "Tokens requested successfully!"
            else
                echo "Validator address is not set."
            fi
            ;;
        3)
            continue
            ;;
        *)
            echo "Invalid choice!"
            ;;
    esac
}
request_tokens
            ;;
        5)
            

            echo "Exiting..."
            sleep 4
            clear
            break
            ;;
        *)
            echo "Invalid choice!"
            ;;
    esac
    read -p "Press any key to continue..."
done
