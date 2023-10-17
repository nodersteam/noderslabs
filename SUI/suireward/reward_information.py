import re
import subprocess

def check_and_write_to_file(object_id):
    try:

        with open("reward.txt", "r") as f:
            existing_rewards = f.readlines()
            existing_object_ids = set(re.findall(r'Object ID: (\S+)', ''.join(existing_rewards)))
    except FileNotFoundError:
        print("reward.txt file not found. Creating a new file.")
        existing_rewards = []
        existing_object_ids = set()

    try:
        object_output = subprocess.check_output(f"sui client object {object_id}", shell=True, stderr=subprocess.DEVNULL, universal_newlines=True)

        if 'staking_pool::StakedSui' in object_output and 'principal:' in object_output:
            principal_line = re.search(r'principal:\s*(\d+)', object_output)

            if principal_line:
                principal = int(principal_line.group(1)) / 1000000000

                if principal > 1.0:
                    with open("reward.txt", "a") as f:
                        f.write(f"Object ID: {object_id}\nAmount: {principal} SUI\n")
    except subprocess.CalledProcessError as e:
        print(f"Error executing command for objectId {object_id}: {e}")

try:
    command_output = subprocess.check_output("sui client objects", shell=True, stderr=subprocess.DEVNULL, universal_newlines=True)
    object_ids = re.findall(r'0x[0-9a-f]{64}', command_output)
except subprocess.CalledProcessError as e:
    print(f"Error executing command: {e}")
    object_ids = []

for object_id in object_ids:
    check_and_write_to_file(object_id)
