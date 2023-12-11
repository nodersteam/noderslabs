import requests
import json
from dotenv import load_dotenv, set_key
import os

# Load environment variables from .env file
load_dotenv()

def get_owned_objects(address):
    """
    Fetches all objects owned by a given address from the Sui network.
    """
    url = "https://fullnode.mainnet.sui.io:443"
    headers = {"Content-Type": "application/json"}
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "suix_getOwnedObjects",
        "params": [address]
    }

    response = requests.post(url, headers=headers, data=json.dumps(payload))
    if response.status_code == 200:
        return response.json()
    else:
        print("Error fetching data from the API")
        return None

def save_object_ids_to_file(object_ids, filename="object_id.txt"):
    """
    Saves a list of object IDs to a text file.
    """
    with open(filename, 'w') as file:
        for object_id in object_ids:
            file.write(object_id + '\n')

def request_address():
    """
    Requests the Sui address from the user and saves it to the .env file.
    """
    address = input("Please enter the Sui address: ")
    set_key(".env", "SUI_ADDRESS", address)
    return address

def get_object_info(object_id):
    """
    Fetches detailed information about a specific object from the Sui network using sui_getObject.
    Includes additional parameters to retrieve more details about the object.
    """
    url = "https://fullnode.mainnet.sui.io:443"
    headers = {"Content-Type": "application/json"}
    additional_params = {
        "showType": True,
        "showOwner": True,
        "showPreviousTransaction": True,
        "showDisplay": False,
        "showContent": True,
        "showBcs": False,
        "showStorageRebate": True
    }
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "sui_getObject",
        "params": [object_id, additional_params]
    }

    response = requests.post(url, headers=headers, data=json.dumps(payload))
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error fetching data for object ID {object_id} from the API")
        return None

def filter_and_save_object_ids(filename="object_id.txt"):
    """
    Reads object IDs from a file, filters them based on their type, and saves the filtered IDs back to the file.
    """
    with open(filename, 'r') as file:
        object_ids = [line.strip() for line in file.readlines()]

    filtered_object_ids = []
    for object_id in object_ids:
        object_info = get_object_info(object_id)
        if object_info and object_info.get('result', {}).get('data', {}).get('type') == "0x3::staking_pool::StakedSui":
            filtered_object_ids.append(object_id)

    with open(filename, 'w') as file:
        for object_id in filtered_object_ids:
            file.write(object_id + '\n')

def get_reward_information():
    """
    Gets reward information for a given Sui address and processes each object ID.
    """
    address = os.getenv("SUI_ADDRESS") or request_address()
    owned_objects = get_owned_objects(address)
    if owned_objects:
        object_ids = [obj['data']['objectId'] for obj in owned_objects['result']['data']]
        save_object_ids_to_file(object_ids)
        filter_and_save_object_ids()
        print("Filtered object IDs saved to object_id.txt")
    else:
        print("No data to save")
