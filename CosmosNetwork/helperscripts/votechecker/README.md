![SOSMOS LOGO](https://github.com/nodersteam/picture/blob/main/%D0%A1%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA%20%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0%202023-07-19%20105624.png?raw=true)

# Cosmos Voting Management Script

## Description
This Python script is a comprehensive voting management tool for projects built on Cosmos SDK. It provides an interactive command-line interface for adding, viewing, editing, and deleting project information. Additionally, the script checks for active votes for these projects, either manually or on a set schedule, and sends updates to a specified Telegram chat via a bot.

## Installation and Usage
1. Save the script to your machine
```
wget https://raw.githubusercontent.com/nodersteam/noderslabs/main/CosmosNetwork/helperscripts/votechecker/cosmosvotechecker.py
```
2. In the terminal, navigate to the directory where the script is located.
3. Run the script by typing `python3 cosmosvotechecker.py`.
4. Follow the prompts in the command-line interface to perform different actions. Don't forget to set TG variables in paragraphs 8 and 9 for correct sending of voting information

## Script Functionality
The script provides the following functionality:

1. Project Management: Users can add, view, edit, or delete information related to a project. This includes the project's name, its API, and the associated wallet address.
2. Voting Check: Users can manually trigger a check for active votes on the projects. The script will display any active votes, along with pertinent information like proposal ID, title, voting start time, voting end time, and whether the associated wallet address has voted.
3. Scheduling: Users can set up automatic checks for active votes on a schedule. Options include checking every hour, every day, or every week.
4. Telegram Settings: Users can set or change the Telegram bot token and chat ID. Updates about active votes will be sent to the specified Telegram chat via the bot.

## Notes
- Before running the script, users need to have Python installed on their machine.
- Users need to have a Telegram bot set up to use the script's Telegram features.
- Project information is stored locally in a text file named `projectsinfo.txt`. If the file does not exist when the script is run, it will be created automatically.
