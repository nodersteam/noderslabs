![Логотип Lava Provider](https://github.com/nodersteam/picture/blob/8aaccf65712d4a3551f15709ae176d69ed6fe00e/66e3a855-9325-4eb7-8767-fb0941eb8a97.png)

# Lava Provider Setup Script

This script automates the setup process for Lava Provider, a service that allows you to provide RPC endpoints for the Lava Network. It guides you through the installation, wallet operations, configuration of the provider, and staking.

## Usage

1. Clone this repository or download the `lava_provider_setup.sh` script.
2. Open a terminal and navigate to the directory where the script is located.
3. Make the script executable by running the following command: `chmod +x lava_provider_setup.sh`.
4. Run the script using the following command: `./lava_provider_setup.sh`.

## Menu Options

The script provides the following menu options:

1. **Prepare server for installation**: Updates the system and installs the required dependencies.
2. **Install Lava**: Clones the Lava repository, installs the selected version, and configures the chain ID and keyring backend.
3. **Wallet operations**: Creates a new wallet or manages existing wallets, including listing wallets.
4. **Install Lava Provider**: Configures the provider URL, project information, and performs provider staking (optional).
5. **Check provider**: Checks the status of the lava-provider service and tests the provider using the `lavad test rpcprovider` command.
6. **Update Lava**: Updates the installed Lava version to the selected tag.
7. **Exit**: Exits the script.

## Update Lava

To update the installed Lava version to the latest release, follow these steps:

1. Run the `lava_provider_setup.sh` script.
2. Choose the "Update Lava" option from the menu.
3. Enter the desired tag to update to.
4. Follow the on-screen instructions to complete the update.

## Check Provider

After installing and configuring Lava Provider, you can check its functionality using the `lavad test rpcprovider` command. This command tests the provider and displays relevant information.

To check the provider, follow these steps:

1. Run the `lava_provider_setup.sh` script.
2. Choose the "Check provider" option from the menu.
3. Wait for the provider check to complete.

## Configure and Stake Provider

After installing Lava Provider, you can configure the provider URL and project information, including the project name, stake amount, provider port, provider moniker, and other parameters.

To configure the provider, follow these steps:

1. Run the `lava_provider_setup.sh` script.
2. Choose the "Install Lava Provider" option from the menu.
3. Follow the on-screen instructions to configure the provider.

If desired, perform the provider staking by providing the required information.
