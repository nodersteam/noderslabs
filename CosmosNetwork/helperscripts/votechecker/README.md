![SOSMOS LOGO](https://github.com/nodersteam/picture/blob/main/%D0%A1%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA%20%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0%202023-07-19%20105624.png?raw=true)

# Cosmos Active Voting Check Tool

## Description

This Python script serves as a project management tool and active voting check tool for networks based on the Cosmos SDK. It automates the voting check process according to a set schedule and sends notifications about voting activities to a predefined Telegram chat.

## Implementation

The tool is implemented using Python 3 and uses several Python libraries such as `os`, `json`, `requests`, `dateutil.parser`, `schedule`, `time`, and `datetime`.

## Features

1. **Project Management**. You can add, view, edit, and delete project information, which includes the project name, the project's API, and the wallet address for the project.
2. **Active Voting Check**. The script checks for active votes for each project based on the project's API data, saves the voting results in a text file and sends the results to a Telegram chat.
3. **Voting Check Schedule**. You can schedule automatic vote checks. The checks can be performed every hour, every day, or every week.
4. **Telegram Settings**. The tool allows you to modify your Telegram bot token and chat ID.

## Prerequisites

- Python 3.6 or higher
- Python libraries: `os`, `json`, `requests`, `python-dateutil`, `schedule`, `time`, `datetime`

## Installation and Running the Script

1. Install Python3, if not already installed. You can download it from the [official Python website](https://www.python.org/downloads/).

2. Clone the repository or download the script file from GitHub.

    ```bash
    git clone https://github.com/your-repo-name
    ```

3. Navigate to the script directory.

    ```bash
    cd your-repo-name
    ```

4. Install the required Python libraries.

    ```bash
    pip install requests python-dateutil schedule
    ```

5. Run the script.

    ```bash
    python script_name.py
    ```

6. Follow the on-screen instructions and enter the corresponding number for the action you want to perform.

## License

[MIT](https://choosealicense.com/licenses/mit/)

