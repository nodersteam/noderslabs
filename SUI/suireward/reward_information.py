import re
import subprocess
from utils import format_number

def get_reward_information():
    try:
        with open("reward.txt", "r") as f:
            existing_rewards = f.readlines()
            print("Existing Reward Information:")
            print(''.join(existing_rewards))
            existing_object_ids = set(re.findall(r'Object ID: (\S+)', ''.join(existing_rewards)))
    except FileNotFoundError:
        print("reward.txt file not found. Creating a new file.")
        existing_rewards = []
        existing_object_ids = set()

    command_output = subprocess.check_output("sui client objects", shell=True, stderr=subprocess.DEVNULL, universal_newlines=True)

    object_ids = re.findall(r'0x[0-9a-f]{64}', command_output)
    print("Retrieving reward information...")

    updated_rewards = []

    for object_id in object_ids:
        if object_id in existing_object_ids:
            continue

        object_output = subprocess.check_output(f"sui client object {object_id}", shell=True, stderr=subprocess.DEVNULL, universal_newlines=True)

        if 'principal:' in object_output:
            id_line = re.search(r'id:\s*(\S+)', object_output)
            principal_line = re.search(r'principal:\s*(\d+)', object_output)

            if id_line and principal_line:
                object_id = id_line.group(1)
                principal = int(principal_line.group(1)) / 1000000000

                if principal >= 1.0:
                    output_line = f"Object ID: {object_id}\nAmount: {format_number(principal)} SUI\n"

                    updated_rewards.append(output_line)
                    existing_object_ids.add(object_id)

    if updated_rewards:
        with open("reward.txt", "a") as f:
            for reward in updated_rewards:
                f.write(reward)
        print("Reward information updated.")
        print("Rewards found in the search:")
        print(''.join(updated_rewards))
    else:
        print("No reward information found.")
