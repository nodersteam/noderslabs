![SOSMOS LOGO](https://github.com/nodersteam/picture/blob/main/%D0%A1%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA%20%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0%202023-07-19%20105624.png?raw=true)

# Script for Withdrawing and Sending Rewards in Cosmos SDK Projects

This script provides a convenient way to withdraw and send rewards in projects built on Cosmos SDK. It allows the user to collect rewards from the validator, check the validator's wallet balance, and send the reward to a specified recipient address.

## Installation and Use

1. Clone the repository or download the `takereward.sh` script file to your device.
2. Make sure the script has execution rights. If not, run `chmod +x takereward.sh` to assign execution rights.
3. Launch the script by running `./takereward.sh`.
4. In the menu, select the options you need to input information about the network, validator, recipient address of the reward, and other parameters.
5. Follow the instructions in the menu for withdrawing and sending rewards.

## Script Functionality

The script provides the following options in the main menu:

1. Enter information about the network, validator, etc.: In this option, the user will be asked to enter information about the network name, validator address, binary file name, token denom, wallet name, and fee amount. This information is saved and will be loaded upon script restart.
2. Enter information about the recipient address of the rewards: In this option, the user will be asked to enter the recipient address of the rewards. If an address has been previously saved, the user will be given the option to use the saved address or enter a new one. The entered address is also saved and will be loaded upon script restart.
3. Check the validator's wallet balance: In this option, the script checks the validator's wallet balance and displays it.
4. Collect rewards from the validator: This option allows the user to collect rewards from the validator.
5. Send reward: In this option, the user will be asked to enter the number of tokens to be sent, after which the reward will be sent to the recipient address.
6. Exit: An option to terminate the script operation.

## Notes

- User-entered information is stored in a profile file. If the profile file does not exist, it will be created automatically.
- When the script is run again, previously saved information will be loaded from the profile file and offered for use or update.

This script provides a convenient way to withdraw and send rewards in projects built on Cosmos SDK and will help automate these processes.
