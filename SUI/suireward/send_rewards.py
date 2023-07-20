import re
import subprocess
import reward_information
from utils import check_object_balance, format_number

def send_rewards_to_address():
    # Retrieve object information
    command_output = subprocess.check_output("sui client objects", shell=True, stderr=subprocess.DEVNULL, universal_newlines=True)

    # Find all object IDs in the output and process each object
    object_ids = re.findall(r'0x[0-9a-f]{64}', command_output)
    filtered_objects = [object_id for object_id in object_ids if check_object_balance(object_id) > 5000000000]

    if len(filtered_objects) > 0:
        existing_rewards = []

        try:
            with open("rewardforsend.txt", "r") as f:
                existing_rewards = f.readlines()
        except FileNotFoundError:
            print("rewardforsend.txt file not found. Creating a new file.")

        print("\nObjects with balance > 5 SUI:")
        for object_id in filtered_objects:
            balance = check_object_balance(object_id)
            formatted_balance = format_number(balance / 1000000000)
            reward_info = f"Object ID: {object_id}\nBalance: {formatted_balance} SUI\n"

            if reward_info not in existing_rewards:
                existing_rewards.append(reward_info)
                print(reward_info)

        recipient_address = input("Enter the recipient address: ")

        option = input("Enter 'one' to send one reward or 'all' to send all: ")
        if option == 'one':
            reward_id = input("Enter the reward ID to send: ")
            if reward_id in existing_rewards:
                # Here is the command to send rewards
                command = f"sui client transfer --to {recipient_address} --object-id {reward_id} --gas-budget 19980000"
                command_output = subprocess.run(command, shell=True, capture_output=True, text=True).stdout
                digest_line = re.search(r'----- Transaction Digest ----\n(\S+)', command_output)

                if digest_line:
                    digest = digest_line.group(1)
                    print(f"Transaction Digest: {digest}")
                    existing_rewards.remove(reward_id)
                else:
                    print("Error: Failed to retrieve transaction digest.")
            else:
                print("Error: Invalid reward ID or reward does not have balance > 5 SUI")
        elif option == 'all':
            for reward_info in existing_rewards:
                reward_id = re.search(r'Object ID: (.*?)\n', reward_info).group(1)
                balance = check_object_balance(reward_id)
                command = f"sui client transfer --to {recipient_address} --object-id {reward_id} --gas-budget 19980000"
                command_output = subprocess.run(command, shell=True, capture_output=True, text=True).stdout
                digest_line = re.search(r'----- Transaction Digest ----\n(\S+)', command_output)

                if digest_line:
                    digest = digest_line.group(1)
                    print(f"Transaction Digest: {digest}")
                    existing_rewards.remove(reward_info)
                else:
                    print(f"Error: Failed to retrieve transaction digest for {reward_id}.")
        else:
            print("Invalid option. Please enter 'one' or 'all'.")

        with open("rewardforsend.txt", "w") as f:
            for reward_info in existing_rewards:
                f.write(reward_info)
    else:
        print("\nNo objects found with balance > 5 SUI")
