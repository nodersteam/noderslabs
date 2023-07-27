#!/bin/bash

# Path to the profile file
PROFILE_FILE="$HOME/cosmos_rewards_profile"

# Function to read a variable value from the profile
read_profile_variable() {
    grep -oP "(?<=^$1=).*" "$PROFILE_FILE"
}

# Function to write a variable value to the profile
write_profile_variable() {
    if [[ -f "$PROFILE_FILE" ]]; then
        sed -i "s/^$1=.*/$1=$2/" "$PROFILE_FILE"
    else
        echo "$1=$2" >> "$PROFILE_FILE"
    fi
    export "$1=$2"
}

# Check if the profile file exists and create it if it doesn't
if [[ ! -f "$PROFILE_FILE" ]]; then
    touch "$PROFILE_FILE"
fi

# Load saved data from the profile file
if [[ -f "$PROFILE_FILE" ]]; then
    source "$PROFILE_FILE"
fi

# Function to collect information from the user
collect_information() {

    source "$PROFILE_FILE"

    # Check if saved information exists in the profile
    if [[ ! -z "$NETWORK_NAME" ]]; then
        echo "Saved information:"
        echo "Network name: $NETWORK_NAME"
        echo "Validator address: $VALIDATOR_ADDRESS"
        echo "Validator wallet address: $VALIDATOR_WALLET_ADDRESS"
        echo "Binary name: $BINARY_NAME"
        echo "Token denomination: $TOKEN_DENOM"
        echo "Wallet name: $WALLET_NAME"
        echo "Commission amount: $COMMISSION_AMOUNT"

        read -p "Use saved information? (y/n): " use_saved_info
        if [[ $use_saved_info == "y" ]]; then
            return
        fi
    fi

    read -p "Network name: " NETWORK_NAME
    echo "export NETWORK_NAME=$NETWORK_NAME" >> cosmos_rewards_profile

    read -p "Validator address: " VALIDATOR_ADDRESS
    echo "export VALIDATOR_ADDRESS=$VALIDATOR_ADDRESS" >> cosmos_rewards_profile

    read -p "Validator wallet address: " VALIDATOR_WALLET_ADDRESS
    echo "export VALIDATOR_WALLET_ADDRESS=$VALIDATOR_WALLET_ADDRESS" >> cosmos_rewards_profile

    read -p "Binary name: " BINARY_NAME
    echo "export BINARY_NAME=$BINARY_NAME" >> cosmos_rewards_profile

    read -p "Token denomination: " TOKEN_DENOM
    echo "export TOKEN_DENOM=$TOKEN_DENOM" >> cosmos_rewards_profile

    read -p "Wallet name: " WALLET_NAME
    echo "export WALLET_NAME=$WALLET_NAME" >> cosmos_rewards_profile

    read -p "Commission amount: " COMMISSION_AMOUNT
    echo "export COMMISSION_AMOUNT=$COMMISSION_AMOUNT" >> cosmos_rewards_profile
}

edit_information() {
    # Load the profile file to update variables in the current shell session
    source "$PROFILE_FILE"
    while true; do

        echo "Saved information:"
        echo "Network name: $NETWORK_NAME"
        echo "Validator address: $VALIDATOR_ADDRESS"
        echo "Validator wallet address: $VALIDATOR_WALLET_ADDRESS"
        echo "Binary name: $BINARY_NAME"
        echo "Token denomination: $TOKEN_DENOM"
        echo "Wallet name: $WALLET_NAME"
        echo "Commission amount: $COMMISSION_AMOUNT"

        echo "------ Edit Information ------"
        echo "1. Edit network name"
        echo "2. Edit validator address"
        echo "3. Edit validator wallet address"
        echo "4. Edit binary name"
        echo "5. Edit token denomination"
        echo "6. Edit wallet name"
        echo "7. Edit commission amount"
        echo "8. Exit"

        read -p "Select an option: " edit_option
        echo "-----------------------------"

        case $edit_option in
            1)
                read -p "Enter new network name: " NETWORK_NAME
                echo "export NETWORK_NAME=$NETWORK_NAME" > "$PROFILE_FILE"
                echo "Network name updated successfully."
                ;;
            2)
                read -p "Enter new validator address: " VALIDATOR_ADDRESS
                echo "export VALIDATOR_ADDRESS=$VALIDATOR_ADDRESS" >> "$PROFILE_FILE"
                echo "Validator address updated successfully."
                ;;
            3)
                read -p "Enter new validator wallet address: " VALIDATOR_WALLET_ADDRESS
                echo "export VALIDATOR_WALLET_ADDRESS=$VALIDATOR_WALLET_ADDRESS" >> "$PROFILE_FILE"
                echo "Validator wallet address updated successfully."
                ;;
            4)
                read -p "Enter new binary name: " BINARY_NAME
                echo "export BINARY_NAME=$BINARY_NAME" >> "$PROFILE_FILE"
                echo "Binary name updated successfully."
                ;;
            5)
                read -p "Enter new token denomination: " TOKEN_DENOM
                echo "export TOKEN_DENOM=$TOKEN_DENOM" >> "$PROFILE_FILE"
                echo "Token denomination updated successfully."
                ;;
            6)
                read -p "Enter new wallet name: " WALLET_NAME
                echo "export WALLET_NAME=$WALLET_NAME" >> "$PROFILE_FILE"
                echo "Wallet name updated successfully."
                ;;
            7)
                read -p "Enter new commission amount: " COMMISSION_AMOUNT
                echo "export COMMISSION_AMOUNT=$COMMISSION_AMOUNT" >> "$PROFILE_FILE"
                echo "Commission amount updated successfully."
                ;;
            8)
                break
                ;;
            *)
                echo "Error: Invalid option."
                ;;
        esac

        echo "-----------------------------"
    done
}


# Function to collect recipient address for rewards
collect_recipient_address() {
    # Load the profile file to update variables in the current shell session
    source "$PROFILE_FILE"

    # Check if a saved recipient address exists in the profile
    if [[ ! -z "$RECIPIENT_ADDRESS" ]]; then
        read -p "Use saved recipient address ($RECIPIENT_ADDRESS)? (y/n): " use_saved_address
        if [[ $use_saved_address == "y" ]]; then
            recipient_address="$RECIPIENT_ADDRESS"
            echo "Recipient address for rewards: $recipient_address"
            return
        fi
    fi

    read -p "Enter recipient address for rewards: " recipient_address
    echo "export RECIPIENT_ADDRESS=$recipient_address" >> cosmos_rewards_profile
}


# Function to check validator balance
check_validator_balance() {
    # Command to get the balance
    balance_command="$BINARY_NAME query bank balances $VALIDATOR_WALLET_ADDRESS --output json | jq -r '.balances[] | select(.denom==\"$TOKEN_DENOM\") | .amount'"

    validator_balance=$(eval "$balance_command")
    echo "Validator wallet balance ($VALIDATOR_WALLET_ADDRESS): $validator_balance $TOKEN_DENOM"
}

# Function to claim rewards from the validator
claim_rewards() {
    # Command to claim rewards
    claim_command="$BINARY_NAME tx distribution withdraw-rewards $VALIDATOR_ADDRESS --from $WALLET_NAME --commission --chain-id $NETWORK_NAME --gas 400000 --fees $COMMISSION_AMOUNT$TOKEN_DENOM --yes"

    echo "Claiming rewards..."
    eval "$claim_command"
    echo "Rewards claimed successfully."
}

# Function to send rewards to a recipient
send_rewards() {
    read -p "Enter the amount of tokens to send: " reward_amount

    # Command to send rewards
    send_command="$BINARY_NAME tx bank send $VALIDATOR_WALLET_ADDRESS $recipient_address $reward_amount$TOKEN_DENOM --from $WALLET_NAME --chain-id $NETWORK_NAME --gas 400000 --fees $COMMISSION_AMOUNT$TOKEN_DENOM --yes"

    echo "Sending rewards..."
    eval "$send_command"
    echo "Rewards sent successfully."
}

# Function to collect API address from the user
collect_api_address() {
    # Check if API address is saved in the profile
    saved_api_address=$(read_profile_variable "API_ADDRESS")
    if [[ ! -z "$saved_api_address" ]]; then
        read -p "Saved API address found: $saved_api_address. Use saved address? (y/n): " use_saved_address
        if [[ $use_saved_address == "y" ]]; then
            API_ADDRESS="$saved_api_address"
            echo "API address: $API_ADDRESS"
            return
        fi
    fi

    read -p "Enter API address: " API_ADDRESS
    echo "export API_ADDRESS=$API_ADDRESS" >> cosmos_rewards_profile
}

# Function to check active votings
#!/bin/bash

# Profile file path
PROFILE_FILE="$HOME/.voting_script_profile"

# Function to read a variable from the profile file
read_profile_variable() {
    local variable_name="$1"
    grep -oP "(?<=^$variable_name=).*" "$PROFILE_FILE"
}

# Function to write a variable to the profile file
write_profile_variable() {
    local variable_name="$1"
    local variable_value="$2"
    echo "$variable_name=$variable_value" >> "$PROFILE_FILE"
}

# Check if the profile file exists, otherwise create it
if [[ ! -e "$PROFILE_FILE" ]]; then
    touch "$PROFILE_FILE"
fi

# Function to check active votings
#!/bin/bash

# Profile file path
PROFILE_FILE="$HOME/.voting_script_profile"

# Function to read a variable from the profile file
read_profile_variable() {
    local variable_name="$1"
    grep -oP "(?<=^$variable_name=).*" "$PROFILE_FILE"
}

# Function to write a variable to the profile file
write_profile_variable() {
    local variable_name="$1"
    local variable_value="$2"
    echo "$variable_name=$variable_value" >> "$PROFILE_FILE"
}

# Check if the profile file exists, otherwise create it
if [[ ! -e "$PROFILE_FILE" ]]; then
    touch "$PROFILE_FILE"
fi

# Function to check active votings
check_active_votings() {
    # Read the API address from the profile file
    API_ADDRESS=$(read_profile_variable "API_ADDRESS")

    # Check if the API address is empty or invalid
    if [[ -z "$API_ADDRESS" ]]; then
        read -p "Enter API address: " API_ADDRESS
        write_profile_variable "API_ADDRESS" "$API_ADDRESS"
    else
        read -p "API address found: $API_ADDRESS. Use this address? (y/n): " use_saved_api
        if [[ $use_saved_api != "y" ]]; then
            read -p "Enter API address: " API_ADDRESS
            echo "export API_ADDRESS=$API_ADDRESS" >> cosmos_rewards_profile
        fi
    fi

    for api_version in 'v1beta1' 'v1'; do
        # Form the API request URL
        API_REQUEST_URL="${API_ADDRESS}cosmos/gov/${api_version}/proposals?pagination.limit=800"

        # Make the API request and save the response in a variable
        API_RESPONSE=$(curl -s "$API_REQUEST_URL")

        # Check if the API response is empty
        if [[ -z "$API_RESPONSE" ]]; then
            echo "No active votings found for API version $api_version."
            continue
        fi

        # Process the API response using jq
        count=$(echo "$API_RESPONSE" | jq -r '.proposals | length')

        if [[ "$count" -eq 0 ]]; then
            echo "No active votings found for API version $api_version."
            continue
        fi

        for ((i = 0; i < count; i++)); do
            status=$(echo "$API_RESPONSE" | jq -r ".proposals[$i].status")

            # Check if the status is "PROPOSAL_STATUS_VOTING_PERIOD"
            if [[ "$status" != "PROPOSAL_STATUS_VOTING_PERIOD" ]]; then
                continue  # Skip this voting if the status is not "PROPOSAL_STATUS_VOTING_PERIOD"
            fi

            voting_id=$(echo "$API_RESPONSE" | jq -r ".proposals[$i].proposal_id // .proposals[$i].id")
            description=$(echo "$API_RESPONSE" | jq -r ".proposals[$i].content.title // .proposals[$i].messages[0].content.title")
            voting_end_time=$(echo "$API_RESPONSE" | jq -r ".proposals[$i].voting_end_time")

            echo "Voting ID: $voting_id"
            echo "Description: $description"
            echo "Voting End Time: $voting_end_time"
            echo "----------------------"
        done
    done
}


# Function to perform voting
perform_voting() {
    read -p "Enter the proposal ID to vote: " proposal_id
    read -p "Enter your vote (yes/no): " vote_option

    # Command to perform voting
    voting_command="$BINARY_NAME tx gov vote $proposal_id $vote_option --from $WALLET_NAME --chain-id $NETWORK_NAME --fees $COMMISSION_AMOUNT$TOKEN_DENOM --yes"

    echo "Performing voting..."
    eval "$voting_command"
    echo "Voting submitted successfully."
}

check_database_weight() {
    read -p "Enter the project's working directory: " project_directory

    # Проверяем, существует ли указанная директория
    if [[ ! -d "$project_directory" ]]; then
        echo "Error: The specified directory does not exist."
        return
    fi

    # Вычисляем вес директории в гигабайтах
    weight=$(du -sh "$project_directory" | awk '{print $1}')

    echo "Database weight of the project directory: $weight GB"
}

set_minimum_gas_price() {
    project_directory=$(read_profile_variable "PROJECT_DIRECTORY")

    if [[ -z "$project_directory" ]]; then
    read -p "Enter the project directory (e.g., $HOME/.project/): " project_directory
    echo "export PROJECT_DIRECTORY=$project_directory" >> cosmos_rewards_profile
else
    read -p "Use the previous project directory ($project_directory)? (y/n): " use_previous_dir
    if [[ $use_previous_dir != "y" ]]; then
        read -p "Enter the project directory (e.g., $HOME/.project/): " project_directory
        echo "export PROJECT_DIRECTORY=$project_directory" >> cosmos_rewards_profile
    fi
fi


    if [[ -z "$project_directory" ]]; then
        echo "Error: Project directory is not specified."
        return
    fi

    read -p "Enter the minimum gas price (e.g., 0.025<denom>): " gas_price

    # Проверяем, существует ли указанная директория
    if [[ ! -d "$project_directory" ]]; then
        echo "Error: The specified directory does not exist."
        return
    fi

    # Заменяем цену газа в файле конфигурации
    sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"$gas_price\"|" "$project_directory/config/app.toml"

    echo "Minimum gas price set successfully."
}

update_peers() {
    project_directory=$(read_profile_variable "PROJECT_DIRECTORY")

    if [[ -z "$project_directory" ]]; then
    read -p "Enter the project directory (e.g., $HOME/.project/): " project_directory
    echo "export PROJECT_DIRECTORY=$project_directory" >> cosmos_rewards_profile
else
    read -p "Use the previous project directory ($project_directory)? (y/n): " use_previous_dir
    if [[ $use_previous_dir != "y" ]]; then
        read -p "Enter the project directory (e.g., $HOME/.project/): " project_directory
        echo "export PROJECT_DIRECTORY=$project_directory" >> cosmos_rewards_profile
    fi
fi

    if [[ -z "$project_directory" ]]; then
        echo "Error: Project directory is not specified."
        return
    fi

    read -p "Enter the peers: " peers

    # Проверяем, существует ли указанная директория
    if [[ ! -d "$project_directory" ]]; then
        echo "Error: The specified directory does not exist."
        return
    fi

    # Обновляем пиры в файле конфигурации
    sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" "$project_directory/config/config.toml"

    echo "Peers updated successfully."
}

use_statesync() {
    read -p "Enter the project directory (e.g., '$HOME/.project/'): " project_directory
    read -p "Enter the binary file name (e.g., stride): " binary_file
    read -p "Enter the service file name (e.g., strided): " service_file
    read -p "Enter the StateSync RPC URL: " state_sync_rpc
    read -p "Enter the StateSync peer: " state_sync_peer

    # Получаем последний блок и его хэш
    latest_height=$(curl -s "$state_sync_rpc/block" | jq -r .result.block.header.height)
    sync_block_height=$((latest_height - 1000))
    sync_block_hash=$(curl -s "$state_sync_rpc/block?height=$sync_block_height" | jq -r .result.block_id.hash)

    # Проверяем, существует ли указанная директория
    if [[ ! -d "$project_directory" ]]; then
        echo "Error: The specified directory does not exist."
        return
    fi

    # Выводим полученные значения
    echo "Project Directory: $project_directory"
    echo "Binary File Name: $binary_file"
    echo "Service File Name: $service_file"
    echo "StateSync RPC URL: $state_sync_rpc"
    echo "StateSync Peer: $state_sync_peer"
    echo "Latest Block Height: $latest_height"
    echo "Sync Block Height: $sync_block_height"
    echo "Sync Block Hash: $sync_block_hash"

    # Проверяем наличие всех значений
    if [[ -z "$project_directory" || -z "$binary_file" || -z "$service_file" || -z "$state_sync_rpc" || -z "$state_sync_peer" || -z "$latest_height" || -z "$sync_block_height" || -z "$sync_block_hash" ]]; then
        echo "Error: Failed to retrieve all required values. This may affect the node's functionality."
        read -p "Are you sure you want to continue? (y/n): " continue_execution
        if [[ "$continue_execution" != "y" ]]; then
            echo "Aborted."
            return
        fi
    fi

    # Останавливаем сервис
    sudo systemctl stop "$service_file"

    # Создаем резервную копию priv_validator_state.json файла
    cp "$project_directory/data/priv_validator_state.json" "$project_directory/priv_validator_state.json.backup"

    # Выполняем unsafe-reset-all с указанием директории проекта
    "$binary_file" tendermint unsafe-reset-all --keep-addr-book --home "$project_directory"

    # Обновляем настройки StateSync в файле конфигурации
    sed -i \
        -e "s|^enable *=.*|enable = true|" \
        -e "s|^rpc_servers *=.*|rpc_servers = \"$state_sync_rpc,$state_sync_rpc\"|" \
        -e "s|^trust_height *=.*|trust_height = $sync_block_height|" \
        -e "s|^trust_hash *=.*|trust_hash = \"$sync_block_hash\"|" \
        -e "s|^persistent_peers *=.*|persistent_peers = \"$state_sync_peer\"|" \
        "$project_directory/config/config.toml"

    # Восстанавливаем priv_validator_state.json из резервной копии
    mv "$project_directory/priv_validator_state.json.backup" "$project_directory/data/priv_validator_state.json"

    # Запускаем сервис и выводим журнал
    sudo systemctl start "$service_file"
    sudo journalctl -u "$service_file" -f --no-hostname -o cat
}

# Main menu
while true; do
    echo "-------- Menu --------"
    echo "1. Enter network and validator information"
    echo "2. Rewards Management"
    echo "3. Voting Management"
    echo "4. Validator Management"
    echo "5. Edit network information"
    echo "6. Exit"

    read -p "Select an option: " option
    echo "----------------------"

    case $option in
        1)
            collect_information
            ;;
        2)
            # Rewards Management submenu
            while true; do
                echo "-------- Rewards Management --------"
                echo "1. Enter recipient address for rewards"
                echo "2. Check validator balance"
                echo "3. Claim rewards from validator"
                echo "4. Send rewards to recipient"
                echo "5. Back"

                read -p "Select an option: " reward_option
                echo "----------------------"

                case $reward_option in
                    1)
                        collect_recipient_address
                        ;;
                    2)
                        check_validator_balance
                        ;;
                    3)
                        claim_rewards
                        ;;
                    4)
                        send_rewards
                        ;;
                    5)
                        break
                        ;;
                    *)
                        echo "Error: Invalid option."
                        ;;
                esac

                echo "----------------------"
            done
            ;;
        3)
            # Voting Management submenu
            while true; do
                echo "-------- Voting Management --------"
                echo "1. Check active votings"
                echo "2. Perform voting"
                echo "3. Back"

                read -p "Select an option: " voting_option
                echo "----------------------"

                case $voting_option in
                    1)
                        check_active_votings
                        ;;
                    2)
                        perform_voting
                        ;;
                    3)
                        break
                        ;;
                    *)
                        echo "Error: Invalid option."
                        ;;
                esac

                echo "----------------------"
            done
            ;;
        4)
            # Validator Management submenu
            while true; do
                echo "-------- Validator Management --------"
                echo "1. Check database weight"
                echo "2. Update peers"
                echo "3. Set minimum gas price"
                echo "4. Use statesync"
                echo "5. Update binary file"
                echo "6. Back"

                read -p "Select an option: " validator_option
                echo "----------------------"

                case $validator_option in
                    1)
                        check_database_weight
                        ;;
                    2)
                        update_peers
                        ;;
                    3)
                        set_minimum_gas_price
                        ;;
                    4)
                        use_statesync
                        ;;
                    5)
                        update_binary_file
                        ;;
                    6)
                        break
                        ;;
                    *)
                        echo "Error: Invalid option."
                        ;;
                esac

                echo "----------------------"
            done
            ;;
        5)
            edit_information
            ;;
        6)
            echo "Goodbye!"
            exit
            ;;
        *)
            echo "Error: Invalid option."
            ;;
    esac

    echo "----------------------"
done
