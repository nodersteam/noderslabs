![SOSMOS LOGO](https://github.com/nodersteam/picture/blob/main/%D0%A1%D0%BD%D0%B8%D0%BC%D0%BE%D0%BA%20%D1%8D%D0%BA%D1%80%D0%B0%D0%BD%D0%B0%202023-07-19%20105624.png?raw=true)

# Cosmos Voting Management Script

## Description
This Python script is a comprehensive voting management tool for projects built on Cosmos SDK. It provides an interactive command-line interface for adding, viewing, editing, and deleting project information. Additionally, the script checks for active votes for these projects, either manually or on a set schedule, and sends updates to a specified Telegram chat via a bot.

## Install Python
`
sudo apt update
sudo apt upgrade
sudo apt install python3 python3-pip
pip3 install requests python-dateutil schedule
`

## Installation and Usage
1. Save the script to your machine

`wget https://raw.githubusercontent.com/nodersteam/noderslabs/main/CosmosNetwork/helperscripts/votechecker/cosmosvotechecker.py`

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

<details>
  <summary> Available APIs </summary>
  
  Here is the list of APIs categorized by their respective projects:

1. Osmosis Mainnet: [API](https://osmosis-api.polkachu.com)
2. CosmosHub Mainnet: [API](https://lcd-cosmoshub.whispernode.com:443)
3. Desmos Mainnet: [API](https://desmos-api.panthea.eu/)
4. Stride Mainnet: [API](https://stride-api.polkachu.com)
5. Rebus Mainnet: [API](https://api.mainnet.rebus.money:1317)
6. Quicksilver Mainnet: [API](https://api.quicksilver.stake-take.com)
7. BitSong Mainnet: [API](https://api-bitsong-ia.cosmosia.notional.ventures)
8. Aura Mainnet: [API](https://lcd.aura.network)
9. BeeZee Mainnet: [API](https://rest.getbze.com)
10. Dig Mainnet: [API](https://api-1-dig.notional.ventures)
11. Empower Mainnet: [API](https://empower-api.polkachu.com)
12. HAQQ Mainnet: [API](https://m-s1-sdk.haqq.sh)
13. Gitopia Mainnet: [API](https://gitopia-api.polkachu.com)
14. GenesisL1 Mainnet: [API](https://api.genesisl1.org)
15. HumansAI Mainnet: [API](https://api.humans-mainnet.stake-take.com)
16. Jackal Mainnet: [API](https://api.jackalprotocol.com)
17. KiChain Mainnet: [API](https://ki.api.ping.pub)
18. Lambda Mainnet: [API](https://lambda-api.jambulmerah.dev)
19. MEME Mainnet: [API](https://api-meme-1.meme.sx)
20. Uptick Mainnet: [API](https://api.uptick.nodestake.top)
21. ARKH Mainnet: [API](https://api.arkh.nodestake.top)
22. Realio Mainnet: [API](https://rest.cosmos.directory/realio)
23. ZetaChain Testnet: [API](https://zetachain-athens.blockpi.network/lcd/v1/public)
24. OKP4 Testnet: [API](https://api-t.okp4.nodestake.top)
25. CrowdControl Testnet: [API](https://crowd-api.theamsolutions.info)
26. Andromeda Testnet: [API](https://andromeda-testnet.api.kjnodes.com)
27. DeFund Testnet: [API](https://api-t.defund.nodestake.top)
28. Source Testnet: [API](https://api-t.source.nodestake.top)
29. Androma Testnet: [API](https://androma-testnet-api.polkachu.com)
30. Dymension Testnet: [API](https://api-t.dymension.nodestake.top)
31. Lava Testnet: [API](https://api-t.lava.nodestake.top)
32. Noria Testnet: [API](https://archive-lcd.noria.nextnet.zone)
33. Babylone Testnet: [API](https://babylon-testnet.nodejumper.io:1317)
    

  
</details>
