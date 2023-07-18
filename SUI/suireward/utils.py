import re
import subprocess

def format_number(number):
    return "{:,.2f}".format(number)

def check_object_balance(object_id):
    command_output = subprocess.check_output(f"sui client object {object_id}", shell=True, stderr=subprocess.DEVNULL, universal_newlines=True)
    balance_line = re.search(r'balance:\s*(\d+)', command_output)
    if balance_line:
        balance = int(balance_line.group(1))
        return balance
    else:
        return 0

def is_valid_address(address):
    # Add address validation logic here
    # For now, let's just check if the address starts with "0x" and has the correct length for a hexadecimal Ethereum address.
    if address.startswith("0x") and len(address) == 42:
        return True
    return False

