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

# Reminder:

If you're installing nodes under a specific profile, don't forget to grant permissions to use Docker with the following commands:
```
sudo usermod -aG sudo <USER>
sudo usermod -aG docker <USER>
```
And then, reboot the server.

After this, you can proceed with the installation.

### Prerequisites

Ensure you have `svn` installed. If not, you can install it using:

For Debian/Ubuntu:
```
sudo apt-get install subversion
```
Download the SHARDEUM/script directory from the repository:

```
svn export https://github.com/nodersteam/noderslabs/trunk/SHARDEUM/script
cd script
chmod +x main.sh install.sh update.sh logs.sh delete_node.sh
./main.sh
```
