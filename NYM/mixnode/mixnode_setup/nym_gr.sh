#!/bin/bash

# Έλεγχος ύπαρξης εντολής
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Έλεγχος και εγκατάσταση curl εάν χρειάζεται
if command_exists curl; then
  echo "Το Curl έχει ήδη εγκατασταθεί"
else
  sudo apt-get update && sudo apt-get install curl -y
fi

# Έλεγχος και εγκατάσταση jq εάν χρειάζεται
if command_exists jq; then
  echo "Το jq έχει ήδη εγκατασταθεί"
else
  sudo apt-get update && sudo apt-get install jq -y
fi

# Φόρτωση bash προφίλ
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi

# Λήψη της τελευταίας ετικέτας από τις κυκλοφορίες του GitHub
get_latest_tag() {
  curl --silent "https://api.github.com/repos/nymtech/nym/releases" |
  jq -r '.[] | select(.name | test("Nym Binaries")) | .tag_name' |
  head -1
}

# Εγκατάσταση κόμβου
setup_node() {
  # Εισαγωγή ονόματος κόμβου, αν δεν υπάρχει
  if [ ! $node_name ]; then
    read -p "Εισάγετε το όνομα του κόμβου: " node_name
    echo 'export node_name='\"${node_name}\" >> $HOME/.bash_profile
  fi

  # Φόρτωση bash προφίλ
  echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
  . $HOME/.bash_profile

  # Εμφάνιση ονόματος κόμβου
  echo 'Το όνομα του κόμβου σας είναι: ' $node_name

  # Ενημέρωση του συστήματος
  sudo apt-get update

  # Εγκατάσταση απαραίτητων πακέτων
  sudo apt-get install -y ufw make clang pkg-config libssl-dev build-essential git 

  # Εγκατάσταση rust
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source $HOME/.cargo/env
  rustup update

  # Διαγραφή παλιού καταλόγου και κλωνοποίηση νέου
  cd $HOME
  rm -rf nym
  git clone https://github.com/nymtech/nym.git

  # Συγκεντρωτική επεξεργασία και μετακίνηση του binary
  cd nym
  latest_tag=$(get_latest_tag)
  git checkout "$latest_tag"
  cargo build --release --bin nym-mixnode
  sudo mv target/release/nym-mixnode /usr/local/bin/

  # Προετοιμασία κόμβου
  nym-mixnode init --id $node_name --host $(curl ipinfo.io/ip)

  # Διαμόρφωση του firewall
  sudo ufw allow 1789,1790,8000,22,80,443/tcp

  # Διαμόρφωση της υπηρεσίας
  sudo bash -c "cat > /etc/systemd/system/nym-mixnode.service" <<EOF
[Unit]
Description=Nym Mixnode

[Service]
User=$USER
ExecStart=/usr/local/bin/nym-mixnode run --id '$node_name'
KillSignal=SIGINT
Restart=on-failure
RestartSec=30
StartLimitInterval=350
StartLimitBurst=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable nym-mixnode
  sudo systemctl restart nym-mixnode
echo "Συγχαρητήρια! Το mixnode σας λειτουργεί. Ήρθε η ώρα να αναθέσετε τα tokens σε αυτό και να το προωθήσετε μεταξύ των φίλων σας."
echo "Υποστηρίξτε και απολαύστε την απόρρητη φύλαξη που παρέχει η NYM."
}

# Ενημέρωση κόμβου
update_node() {
  echo "Εξαγωγή των τελευταίων πληροφοριών εκδόσεων από το GitHub..."
  latest_tag=$(get_latest_tag)

  echo "Η τελευταία έκδοση είναι η $latest_tag. Θέλετε να ενημερωθείτε σε αυτή την έκδοση; [Y/n]"
  read -r answer

  case ${answer:0:1} in
    y|Y )
        echo "Ενημέρωση στην έκδοση $latest_tag..."
        cd $HOME/nym
        git fetch
        git checkout "$latest_tag"
        cargo build --release --bin nym-mixnode
        sudo mv target/release/nym-mixnode /usr/local/bin/nym-mixnode
        sudo systemctl restart nym-mixnode
    ;;
    * )
        echo "Η ενημέρωση ακυρώθηκε."
    ;;
  esac
}

# Έλεγχος κατάστασης κόμβου
check_status() {
  node_status=$(sudo systemctl is-active nym-mixnode)
  if [ "$node_status" = "active" ]; then
    echo "Η υπηρεσία Nym Mixnode είναι ενεργή και λειτουργεί."
  else
    echo "Η υπηρεσία Nym Mixnode δεν είναι ενεργή."
  fi
}

# Απεγκατάσταση κόμβου
remove_node() {
  sudo systemctl stop nym-mixnode
  sudo systemctl disable nym-mixnode
  sudo rm /usr/local/bin/nym-mixnode
  sudo rm /etc/systemd/system/nym-mixnode.service
  sudo systemctl daemon-reload
  rm -rf $HOME/nym
  echo "Ο κόμβος Nym αφαιρέθηκε με επιτυχία."
}

# Μενού επιλογών κόμβου
while true; do
  PS3='Παρακαλώ εισάγετε την επιλογή σας: '
  options=("Εγκατάσταση Κόμβου" "Έλεγχος Κόμβου" "Ενημέρωση Κόμβου" "Απεγκατάσταση Κόμβου" "Έξοδος")
  select opt in "${options[@]}"
  do
      case $opt in
          "Εγκατάσταση Κόμβου")
              setup_node
              break
              ;;
          "Έλεγχος Κόμβου")
              check_status
              break
              ;;
          "Ενημέρωση Κόμβου")
              update_node
              break
              ;;
          "Απεγκατάσταση Κόμβου")
              remove_node
              break
              ;;
          "Έξοδος")
              break 2
              ;;
          *) echo "Λάθος επιλογή $REPLY";;
      esac
  done
done
