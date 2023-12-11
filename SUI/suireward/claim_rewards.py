import re
import subprocess

def claim_rewards():
    try:
        with open("object_id.txt", "r") as f:
            reward_ids = [line.strip() for line in f if line.strip()]
    except FileNotFoundError:
        print("No rewards file found.")
        return

    if not reward_ids:
        print("No rewards found.")
        return

    print("Rewards:")
    for reward_id in reward_ids:
        print(reward_id)

    reward_id_input = input("Enter the reward ID to withdraw (or 'all' to withdraw all rewards): ")

    if reward_id_input.lower() == "all":
        for reward_id in reward_ids:
            command = f"sui client call --package 0x3 --module sui_system --function request_withdraw_stake --args 0x5 {reward_id} --gas-budget 19980000"
            print(f"Withdrawing reward with ID: {reward_id}...")

            command_output = subprocess.run(command, shell=True, capture_output=True, text=True).stdout

            digest_line = re.search(r'----- Transaction Digest ----\n(\S+)', command_output)
            if digest_line:
                digest = digest_line.group(1)
                print(f"Transaction Digest: {digest}")

                with open("transaction_digest.txt", "a") as f:
                    f.write(f"{digest}\n")
            else:
                print("Error: Failed to retrieve transaction digest.")

        # Clear the reward.txt file after processing all rewards
        with open("object_id.txt", "w") as f:
            pass
    else:
        if reward_id_input in reward_ids:
            command = f"sui client call --package 0x3 --module sui_system --function request_withdraw_stake --args 0x5 {reward_id_input} --gas-budget 19980000"
            print(f"Withdrawing reward with ID: {reward_id_input}...")

            command_output = subprocess.run(command, shell=True, capture_output=True, text=True).stdout

            digest_line = re.search(r'----- Transaction Digest ----\n(\S+)', command_output)
            if digest_line:
                digest = digest_line.group(1)
                print(f"Transaction Digest: {digest}")

                with open("transaction_digest.txt", "a") as f:
                    f.write(f"{digest}\n")
            else:
                print("Error: Failed to retrieve transaction digest.")

            # Update reward.txt to remove the processed reward ID
            updated_reward_ids = [id for id in reward_ids if id != reward_id_input]
            with open("object_id.txt", "w") as f:
                for id in updated_reward_ids:
                    f.write(f"{id}\n")
        else:
            print("Invalid reward ID entered.")
