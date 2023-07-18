![Логотип Lava Provider](https://github.com/nodersteam/picture/blob/main/myxnodepic.png?raw=true)

# Nym Mixnode Setup Script Repository

## About the Script

This repository houses our team's automated setup script for Nym mixnodes, located [here](https://github.com/nodersteam/noderslabs/blob/main/NYM/mixnode/mixnode.sh). The purpose of this script is to simplify and streamline the process of setting up a Nym mixnode, making it easy and accessible for anyone to contribute to the Nym network and uphold the values of privacy and freedom on the internet.

This setup script takes care of a multitude of tasks, including but not limited to:

- Checking and installing necessary dependencies like `curl` and `jq`
- Loading and updating user's bash profile
- Fetching latest Nym mixnode version from GitHub releases
- Setting up the node with user input or pre-existing configuration
- Building the node and moving binaries
- Configuring the firewall and the system service for the node
- Offering options to check the status, update, or remove the node

In addition to automating the setup process, the script also offers functionalities to update the node to the latest version, check the status of the node, or completely remove the node if necessary.

## Localization

Recognizing the global interest and participation in the Nym project, we have localized this script to several languages to enhance accessibility and ease-of-use for users around the world. Currently, the script is available in the following languages:

- English
- Indonesian (Bahasa Indonesia)
- German (Deutsch)
- Russian (Русский)
- Spanish (Español)

## Downloading and Running the Script

To download and run the script on your Linux server, use the following commands:

```bash
wget https://github.com/nodersteam/noderslabs/raw/main/NYM/mixnode/mixnode.sh
chmod +x mixnode.sh
./mixnode.sh
