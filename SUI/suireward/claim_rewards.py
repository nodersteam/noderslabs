import re
import subprocess

def claim_rewards():
    try:
        with open("reward.txt", "r") as f:
            reward_lines = f.readlines()
    except FileNotFoundError:
        reward_lines = []

    if not reward_lines:
        print("No rewards found.")
        return

    print("Rewards:")
    for line in reward_lines:
        print(line.strip())

    reward_id = input("Enter the reward ID to withdraw (or 'all' to withdraw all rewards): ")

    if reward_id.lower() == "all":
        for line in reward_lines:
            object_id_line = re.search(r'Object ID: (\S+)', line)
            if object_id_line:
                object_id = object_id_line.group(1)
                command = f"sui client call --package 0x3 --module sui_system --function request_withdraw_stake --args 0x5 {object_id} --gas-budget 19980000"
                print(f"Withdrawing reward with ID: {object_id}...")

                command_output = subprocess.run(command, shell=True, capture_output=True, text=True).stdout

                digest_line = re.search(r'----- Transaction Digest ----\n(\S+)', command_output)
                if digest_line:
                    digest = digest_line.group(1)
                    print(f"Transaction Digest: {digest}")

                    with open("transaction_digest.txt", "w") as f:
                        f.write(digest)
                else:
                    print("Error: Failed to retrieve transaction digest.")

        with open("reward.txt", "w") as f:
            pass
    else:
        command = f"sui client call --package 0x3 --module sui_system --function request_withdraw_stake --args 0x5 {reward_id} --gas-budget 19980000"
        print(f"Withdrawing reward with ID: {reward_id}...")

        command_output = subprocess.run(command, shell=True, capture_output=True, text=True).stdout

        digest_line = re.search(r'----- Transaction Digest ----\n(\S+)', command_output)
        if digest_line:
            digest = digest_line.group(1)
            print(f"Transaction Digest: {digest}")

            with open("transaction_digest.txt", "w") as f:
                f.write(digest)
        else:
            print("Error: Failed to retrieve transaction digest.")

        updated_reward_lines = [l for l in reward_lines if not l.startswith(f"Object ID: {reward_id}")]
        with open("reward.txt", "w") as f:
            f.writelines(updated_reward_lines)
