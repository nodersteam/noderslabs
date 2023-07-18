import re
import subprocess

def vote_for_gas_price():
    try:
        with open("UnverifiedValidatorOperationCap.txt", "r") as f:
            object_cap_id = f.read().strip()
    except FileNotFoundError:
        print("UnverifiedValidatorOperationCap.txt not found.")
        object_cap_id = ""

    use_saved_object_cap_id = input("Use saved UnverifiedValidatorOperationCap? (y/n): ")
    if use_saved_object_cap_id.lower() == "n":
        object_cap_id = input("Enter the new UnverifiedValidatorOperationCap: ")
        with open("UnverifiedValidatorOperationCap.txt", "w") as f:
            f.write(object_cap_id)

    gas_price = input("Enter the gas price for the next epoch: ")

    command = f"sui client call --package 0x3 --module sui_system --function request_set_gas_price --args 0x5 {object_cap_id} {gas_price} --gas-budget 15000000"

    try:
        output = subprocess.check_output(command, shell=True, stderr=subprocess.DEVNULL, universal_newlines=True)
        print("Successfully voted for gas price.")
        digest_line = re.search(r'----- Transaction Digest ----\n(\S+)', output)
        if digest_line:
            digest = digest_line.group(1)
            print(f"Transaction Digest: {digest}")

            with open("transaction_digest.txt", "w") as f:
                f.write(digest)
        else:
            print("Error: Failed to retrieve transaction digest.")
    except subprocess.CalledProcessError:
        print("Failed to vote for gas price.")
