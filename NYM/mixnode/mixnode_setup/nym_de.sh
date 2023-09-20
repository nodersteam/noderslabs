#!/bin/bash

# Überprüfen, ob Befehl existiert
befehl_existiert() {
  command -v "$1" >/dev/null 2>&1
}

# Überprüfen und installieren Sie curl falls nötig
if befehl_existiert curl; then
  echo "Curl ist bereits installiert"
else
  sudo apt-get update && sudo apt-get install curl -y
fi

# Überprüfen und installieren Sie jq falls nötig
if befehl_existiert jq; then
  echo "jq ist bereits installiert"
else
  sudo apt-get update && sudo apt-get install jq -y
fi

# Bash-Profil laden
bash_profil=$HOME/.bash_profile
if [ -f "$bash_profil" ]; then
    . $HOME/.bash_profile
fi

# Aktuellste Version von GitHub Releases holen
aktuellste_version_holen() {
  curl --silent "https://api.github.com/repos/nymtech/nym/releases" |
  jq -r '.[] | select(.name | test("Nym Binaries")) | .tag_name' |
  head -1
}

# Einrichtung des Nodes
einrichtung_des_Nodes() {
  # Geben Sie den Nodenamen ein, wenn er nicht existiert
  if [ ! $Node_name ]; then
    read -p "Geben Sie den Nodenamen ein: " Node_name
    echo 'export Node_name='\"${Node_name}\" >> $HOME/.bash_profile
  fi

  # Bash-Profil laden
  echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
  . $HOME/.bash_profile

  # Nodenamen ausgeben
  echo 'Ihr Nodename: ' $Node_name

  # System aktualisieren
  sudo apt-get update

  # Notwendige Pakete installieren
  sudo apt-get install -y ufw make clang pkg-config libssl-dev build-essential git 

  # Rust installieren
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source $HOME/.cargo/env
  rustup update

  # Altes Verzeichnis entfernen und neues klonen
  cd $HOME
  rm -rf nym
  git clone https://github.com/nymtech/nym.git

  # Erstellen und verschieben des Binärs
  cd nym
  aktuellste_version=$(aktuellste_version_holen)
  git checkout "$aktuellste_version"
  cargo build --release --bin nym-mixnode
  sudo mv target/release/nym-mixnode /usr/local/bin/

  # Node initialisieren
  nym-mixnode init --id $Node_name --host $(curl ipinfo.io/ip)

  # Firewall konfigurieren
  sudo ufw allow 1789,1790,8000,22,80,443/tcp

  # Service konfigurieren
  sudo bash -c "cat > /etc/systemd/system/nym-mixnode.service" <<EOF
[Unit]
Description=Nym Mixnode

[Service]
User=$USER
ExecStart=/usr/local/bin/nym-mixnode run --id '$Node_name'
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
echo "Herzlichen Glückwunsch! Ihr Mixnode läuft. Es ist Zeit, Tokens darauf zu delegieren und ihn bei Ihren Freunden zu bewerben."
echo "Unterstützen und genießen Sie Datenschutz und Sicherheit im Internet von NYM!"
}

# Node aktualisieren
Node_aktualisieren() {
  echo "Abrufen der neuesten Versionsinformationen von GitHub..."
  aktuellste_version=$(aktuellste_version_holen)

  echo "Neueste Version ist $aktuellste_version. Möchten Sie auf diese Version aktualisieren? [Y/n]"
  read -r antwort

  case ${antwort:0:1} in
    y|Y )
        echo "Aktualisieren auf Version $aktuellste_version..."
        cd $HOME/nym
        git fetch
        git checkout "$aktuellste_version"
        cargo build --release --bin nym-mixnode
        sudo mv target/release/nym-mixnode /usr/local/bin/nym-mixnode
        sudo systemctl restart nym-mixnode
    ;;
    * )
        echo "Aktualisierung abgebrochen."
    ;;
  esac
}

# Nodestatus überprüfen
status_ueberpruefen() {
  Node_status=$(sudo systemctl is-active nym-mixnode)
  if [ "$Node_status" = "active" ]; then
    echo "Nym Mixnode Dienst ist aktiv und läuft."
  else
    echo "Nym Mixnode Dienst ist inaktiv."
  fi
}

# Node entfernen
Node_entfernen() {
  sudo systemctl stop nym-mixnode
  sudo systemctl disable nym-mixnode
  sudo rm /usr/local/bin/nym-mixnode
  sudo rm /etc/systemd/system/nym-mixnode.service
  sudo systemctl daemon-reload
  rm -rf $HOME/nym
  echo "Nym Node erfolgreich entfernt."
}

# Node Aktionsmenü
while true; do
  PS3='Bitte geben Sie Ihre Wahl ein: '
  optionen=("Node einrichten" "Node überprüfen" "Node aktualisieren" "Node entfernen" "Beenden")
  select opt in "${optionen[@]}"
  do
      case $opt in
          "Node einrichten")
              einrichtung_des_Nodes
              break
              ;;
          "Node überprüfen")
              status_ueberpruefen
              break
              ;;
          "Node aktualisieren")
              Node_aktualisieren
              break
              ;;
          "Node entfernen")
              Node_entfernen
              break
              ;;
          "Beenden")
              break 2
              ;;
          *) echo "ungültige Option $REPLY";;
      esac
  done
done
