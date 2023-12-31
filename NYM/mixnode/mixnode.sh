#!/bin/bash

# Clear screen and display logo 1
clear
cat << "EOF"
ooooo      ooo oooooo   oooo ooo        ooooo      ooo        ooooo ooooo ooooooo  ooooo ooooo      ooo   .oooooo.   oooooooooo.   oooooooooooo
`888b.     `8'  `888.   .8'  `88.       .888'      `88.       .888' `888'  `8888    d8'  `888b.     `8'  d8P'  `Y8b  `888'   `Y8b  `888'     `8
 8 `88b.    8    `888. .8'    888b     d'888        888b     d'888   888     Y888..8P     8 `88b.    8  888      888  888      888  888        
 8   `88b.  8     `888.8'     8 Y88. .P  888        8 Y88. .P  888   888      `8888'      8   `88b.  8  888      888  888      888  888oooo8    
 8     `88b.8      `888'      8  `888'   888        8  `888'   888   888     .8PY888.     8     `88b.8  888      888  888      888  888    "   
 8       `888       888       8    Y     888        8    Y     888   888    d8'  `888b    8       `888  `88b    d88'  888     d88'  888       o
o8o        `8      o888o     o8o        o888o      o8o        o888o o888o o888o  o88888o o8o        `8   `Y8bood8P'  o888bood8P'   o888ooooood8
EOF

sleep 2

# Clear screen and display logo 2

cat << "EOF"
 _            __  _  _   ___   ___   ___  ___  ___  __   _____  ___    _    __  __ 
| |__  _  _  | _|| \| | / _ \ |   \ | __|| _ \/ __||_ | |_   _|| __|  /_\  |  \/  |
| '_ \| || | | | | .` || (_) || |) || _| |   /\__ \ | |   | |  | _|  / _ \ | |\/| |
|_.__/ \_, | | | |_|\_| \___/ |___/ |___||_|_\|___/ | |   |_|  |___|/_/ \_\|_|  |_|
       |__/  |__|                                  |__|                            
EOF
sleep 1

echo "Welcome to NYM Mixnode setup"
echo "Please choose your language:"
echo "1) English"
echo "2) Indonesian (Bahasa Indonesia)"
echo "3) German (Deutsch)"
echo "4) Russian (Русский)"
echo "5) Spanish (Español)"
echo "6) Greek (Ελληνικά)"
echo "7) Quit"

read choice

case $choice in
    1)
        curl -s -o nym_en.sh https://raw.githubusercontent.com/nodersteam/noderslabs/main/NYM/mixnode/mixnode_setup/nym_en.sh
        [ $? -eq 0 ] && bash nym_en.sh || echo "Failed to download script"
        ;;
    2)
        curl -s -o nym_ind.sh https://raw.githubusercontent.com/nodersteam/noderslabs/main/NYM/mixnode/mixnode_setup/nym_ind.sh
        [ $? -eq 0 ] && bash nym_ind.sh || echo "Failed to download script"
        ;;
    3)
        curl -s -o nym_de.sh https://raw.githubusercontent.com/nodersteam/noderslabs/main/NYM/mixnode/mixnode_setup/nym_de.sh
        [ $? -eq 0 ] && bash nym_de.sh || echo "Failed to download script"
        ;;
    4)
        curl -s -o nym_ru.sh https://raw.githubusercontent.com/nodersteam/noderslabs/main/NYM/mixnode/mixnode_setup/nym_ru.sh
        [ $? -eq 0 ] && bash nym_ru.sh || echo "Failed to download script"
        ;;
    5)
        curl -s -o nym_es.sh https://raw.githubusercontent.com/nodersteam/noderslabs/main/NYM/mixnode/mixnode_setup/nym_es.sh
        [ $? -eq 0 ] && bash nym_es.sh || echo "Failed to download script"
        ;;
    6)
        curl -s -o nym_gr.sh https://raw.githubusercontent.com/nodersteam/noderslabs/main/NYM/mixnode/mixnode_setup/nym_gr.sh
        [ $? -eq 0 ] && bash nym_gr.sh || echo "Failed to download script"
        ;;
    7)
        echo "Exiting."
        exit 0
        ;;
    *)
        echo "Invalid option. Exiting."
        exit 1
        ;;
esac
