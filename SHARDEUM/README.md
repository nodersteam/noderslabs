![image](https://github.com/nodersteam/noderslabs/assets/94483941/171778f9-7198-40b0-85cf-d3d6a3a2db9a)


# Shardeum Node Installer

A script for automating the installation, updating, and management of the Shardeum Node on your server.

## Description

With this script, you can:

- Prepare the server for installation.
- Install the Shardeum Node.
- Update the Node.
- View logs.
- Fetch the Dashboard address.
- Stop and remove the node.

## Getting Started

### Prerequisites

Ensure you have `svn` installed. If not, you can install it using:

- For Debian/Ubuntu:
  ```bash
  sudo apt-get install subversion

Download the SHARDEUM/script directory from the repository:

  ```bash
svn export https://github.com/nodersteam/noderslabs/trunk/SHARDEUM/script
cd script
chmod +x main.sh server.sh install.sh update.sh logs.sh dashboard_address.sh delete_node.sh
./main.sh
