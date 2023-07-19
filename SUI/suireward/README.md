![Lava Provider Logo](https://github.com/nodersteam/picture/blob/main/suipic.png?raw=true)

# SUI Reward and GasPrice Vote Script

## About the Script

This script is a contribution to the SUI Project by our team. It's designed to automate the processes related to rewards and voting within the SUI platform.

The main functionalities of the script are:

1. **Reward Withdrawal:** The script automates the process of withdrawing rewards from the SUI validator. This ensures that the rewards are accurately and efficiently withdrawn, reducing the manual efforts involved.

2. **Reward Sending:** After the rewards are withdrawn, the script automatically sends these rewards to a designated address. This streamlines the reward distribution process and ensures timely dispatch.

3. **Gas Price Voting:** The script also provides a feature to vote for the gas price on the SUI platform. This allows for easy participation in the decision-making process of the SUI platform.

The script is composed of several modules:

- `main.py`: The entry point of the script.
- `reward_information.py`: Module responsible for handling reward information.
- `send_rewards.py`: Module for sending rewards.
- `utils.py`: Contains utility functions used across the script.
- `vote_for_gas.py`: Handles voting for gas distribution.
- `claim_rewards.py`: Handles the process of claiming rewards.

## How to Download and Run the Script

To use the script, follow these steps:

1. **Prerequisites:** This script is written in Python. Ensure that you have Python (version 3.7 or higher) installed on your system. If not, you can download it from [here](https://www.python.org/downloads/). Additionally, you will also need `git` to clone the repository.

2. **Clone the Repository:** Open your terminal and navigate to the directory where you want to clone the repository. Use the following command to clone the repository:

    ```bash
    sudo apt-get install subversion
    svn export https://github.com/nodersteam/noderslabs/trunk/SUI/suireward
    ```

3. **Navigate to the Script:** Move into the cloned repository and then into the `SUI/suireward` directory using:

    ```bash
    cd suireward
    ```

4. **Run the Script:** Use Python to run the script with the following command:

    ```bash
    python main.py
    ```

Please ensure you carefully follow these steps for a successful operation of the script. Feel free to raise any issues you encounter or suggest improvements via the repository's issue tracker.
