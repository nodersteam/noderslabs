import os
import json
import requests
from dateutil.parser import isoparse
import schedule
import time
import datetime

TOKEN = ""

chat_id = ""
next_check_time = None
interval = None

def send_telegram_message(message):
    url = f"https://api.telegram.org/bot{TOKEN}/sendMessage"
    data = {"chat_id": chat_id, "text": message}
    try:
        response = requests.post(url, data=data)
        response.raise_for_status()
    except Exception as e:
        print(f"Failed to send message: {str(e)}")

def menu():
    while True:
        print("""
Welcome to our system!

---- Project Management ----
1. Add project information for checking active votes
2. View project information
3. Edit project information
4. Delete project information

---- Voting Check ----
5. Check active votes
6. Set schedule for automatic vote check
7. Start automatic vote check

---- Telegram Settings ----
8. Change Telegram bot token
9. Change Telegram chat ID

10. Exit
        """)

        option = input("Enter the number of your chosen option: ")

        if option == '1':
            add_project_info()
        elif option == '2':
            view_project_info()
        elif option == '3':
            edit_project_info()
        elif option == '4':
            delete_project_info()
        elif option == '5':
            check_active_votes()
        elif option == '6':
            schedule_checks()
        elif option == '7':
            start_auto_check_votes()
        elif option == '8':
            change_telegram_token()
        elif option == '9':
            change_telegram_chat_id()
        elif option == '10':
            print("Exiting the program...")
            break
        else:
            print("Invalid option entered. Please try again.")

def add_project_info():
    project_name = input("Enter the project name: ")
    project_api = input("Enter the project API: ")
    wallet_address = input("Enter the wallet address for this project: ")

    project_info = {
        'project_name': project_name,
        'project_api': project_api,
        'wallet_address': wallet_address,
    }

    projects = []
    if os.path.isfile('projectsinfo.txt'):
        with open('projectsinfo.txt', 'r') as file:
            projects = json.load(file)

    projects.append(project_info)

    with open('projectsinfo.txt', 'w') as file:
        json.dump(projects, file, ensure_ascii=False, indent=4)

    print("Project information added successfully.")

def view_project_info():
    if not os.path.isfile('projectsinfo.txt'):
        print("The file 'projectsinfo.txt' does not exist.")
        return

    with open('projectsinfo.txt', 'r') as file:
        projects = json.load(file)

    if not projects:
        print("No project information available.")
        return

    print("Project information:\n")
    for idx, project_info in enumerate(projects, 1):
        print(f"{idx}.")
        print(f"Project Name: {project_info['project_name']}")
        print(f"Project API: {project_info['project_api']}")
        print(f"Wallet Address: {project_info['wallet_address']}\n")

def edit_project_info():
    if not os.path.isfile('projectsinfo.txt'):
        print("The file 'projectsinfo.txt' does not exist.")
        return

    with open('projectsinfo.txt', 'r') as file:
        projects = json.load(file)

    if not projects:
        print("No project information available.")
        return

    view_project_info()

    while True:
        project_idx = input("Enter the number of the project you want to edit: ")
        if not project_idx.isdigit() or int(project_idx) < 1 or int(project_idx) > len(projects):
            print("Invalid option entered. Please try again.")
            continue

        project_idx = int(project_idx) - 1
        project_name = input(f"Enter the new project name (current: {projects[project_idx]['project_name']}): ")
        project_api = input(f"Enter the new project API (current: {projects[project_idx]['project_api']}): ")
        wallet_address = input(f"Enter the new wallet address (current: {projects[project_idx]['wallet_address']}): ")

        projects[project_idx] = {
            'project_name': project_name,
            'project_api': project_api,
            'wallet_address': wallet_address,
        }

        with open('projectsinfo.txt', 'w') as file:
            json.dump(projects, file, ensure_ascii=False, indent=4)

        print("Project information updated successfully.")
        break

def delete_project_info():
    if not os.path.isfile('projectsinfo.txt'):
        print("The file 'projectsinfo.txt' does not exist.")
        return

    with open('projectsinfo.txt', 'r') as file:
        projects = json.load(file)

    if not projects:
        print("No project information available.")
        return

    view_project_info()

    while True:
        project_idx = input("Enter the number of the project you want to delete: ")
        if not project_idx.isdigit() or int(project_idx) < 1 or int(project_idx) > len(projects):
            print("Invalid option entered. Please try again.")
            continue

        project_idx = int(project_idx) - 1
        del projects[project_idx]

        with open('projectsinfo.txt', 'w') as file:
            json.dump(projects, file, ensure_ascii=False, indent=4)

        print("Project information deleted successfully.")
        break
        
def change_telegram_token():
    global TOKEN
    new_token = input("Enter your new Telegram bot token: ")
    TOKEN = new_token
    print("Telegram bot token has been updated successfully.")

def change_telegram_chat_id():
    global chat_id
    new_chat_id = input("Enter your new Telegram chat ID: ")
    chat_id = new_chat_id
    print("Telegram chat ID has been updated successfully.")

def check_active_votes():
    global next_check_time, interval
    if interval:
        next_check_time = datetime.datetime.now() + interval

    if not os.path.isfile('projectsinfo.txt'):
        print("The file 'projectsinfo.txt' does not exist.")
        return

    with open('projectsinfo.txt', 'r') as file:
        projects = json.load(file)

    for project_info in projects:
        project_api = project_info['project_api']
        project_wallet = project_info['wallet_address']
        
        project_votes_found = False
        for api_version in ['v1beta1', 'v1']:
            url = f'{project_api}/cosmos/gov/{api_version}/proposals?pagination.limit=600'
            response = requests.get(url)
            if response.status_code == 200:
                proposals = response.json().get('proposals', [])
                if proposals:
                    active_proposals = [p for p in proposals if p.get('status') == "PROPOSAL_STATUS_VOTING_PERIOD"]
                    if not active_proposals:
                        continue
                    print(f"\nActive votes for {project_info['project_name']}:\n")
                    project_votes_found = True
                    with open(f"{project_info['project_name']}.txt", 'w') as f:
                        f.write(f"Active votes for {project_info['project_name']}:\n")
                        for proposal in active_proposals:
                            proposal_id = proposal.get('proposal_id')
                            for api_version_vote in ['v1beta1', 'v1']:
                                vote_url = f'{project_api}/cosmos/gov/{api_version_vote}/proposals/{proposal_id}/votes/{project_wallet}'
                                vote_response = requests.get(vote_url)
                                if vote_response.status_code == 200:
                                    break
                            voted = "Yes" if vote_response.status_code == 200 else "No"
                            title = proposal.get('content', {}).get('title')
                            start_time = isoparse(proposal.get('voting_start_time')).strftime('%d %B %Y, %H:%M')
                            end_time = isoparse(proposal.get('voting_end_time')).strftime('%d %B %Y, %H:%M')
                            f.write(f"\nProposal ID: {proposal_id}")
                            f.write(f"\nTitle: {title}")
                            f.write(f"\nVoting Start Time: {start_time}")
                            f.write(f"\nVoting End Time: {end_time}")
                            f.write(f"\nVoted: {voted}\n")
                            print(f"\nProposal ID: {proposal_id}")
                            print(f"Title: {title}")
                            print(f"Voting Start Time: {start_time}")
                            print(f"Voting End Time: {end_time}")
                            print(f"Voted: {voted}\n")
                            send_telegram_message(f"\nProject: {project_info['project_name']}\nProposal ID: {proposal_id}\nTitle: {title}\nVoting Start Time: {start_time}\nVoting End Time: {end_time}\nVoted: {voted}\n")
                break
        if not project_votes_found:
            print(f"{project_info['project_name']}: No new votes found.")

def schedule_checks():
    global interval
    while True:
        print("""
Please choose one of the following options for scheduling:
1. Every hour
2. Every day
3. Every week
        """)

        option = input("Enter the number of your chosen option: ")

        if option == '1':
            interval = datetime.timedelta(hours=1)
            print("Schedule set to check every hour.")
            break
        elif option == '2':
            interval = datetime.timedelta(days=1)
            print("Schedule set to check every day.")
            break
        elif option == '3':
            interval = datetime.timedelta(weeks=1)
            print("Schedule set to check every week.")
            break
        else:
            print("Invalid option entered. Please try again.")

def start_auto_check_votes():
    global next_check_time
    if not interval:
        print("No schedule set. Please set a schedule first.")
        return

    print("Starting automatic vote check...")
    print("You can now safely close your screen session.")
    print("To detach from the screen session, press Ctrl + A, then D.")
    print("To reattach to the screen session, type 'screen -r' in the terminal.")
    while True:
        if next_check_time and datetime.datetime.now() >= next_check_time:
            print(f"\nStarting vote check... Next check in: {interval}")
            check_active_votes()
        time.sleep(1)

if __name__ == "__main__":
    menu()

