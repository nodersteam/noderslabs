#!/bin/bash

# Periksa apakah perintah ada
perintah_ada() {
  command -v "$1" >/dev/null 2>&1
}

# Periksa dan instal curl jika perlu
if perintah_ada curl; then
  echo "Curl sudah terpasang"
else
  sudo apt-get update && sudo apt-get install curl -y
fi

# Periksa dan instal jq jika perlu
if perintah_ada jq; then
  echo "jq sudah terpasang"
else
  sudo apt-get update && sudo apt-get install jq -y
fi

# Muat profil bash
profil_bash=$HOME/.bash_profile
if [ -f "$profil_bash" ]; then
    . $HOME/.bash_profile
fi

# Dapatkan tag terakhir dari GitHub releases
dapatkan_tag_terakhir() {
  curl --silent "https://api.github.com/repos/nymtech/nym/releases" |
  jq -r '.[] | select(.name | test("Nym Binaries")) | .tag_name' |
  head -1
}

# Setup Node
atur_node() {
  # Masukkan nama node jika tidak ada
  if [ ! $nama_node ]; then
    read -p "Masukkan nama node: " nama_node
    echo 'export nama_node='\"${nama_node}\" >> $HOME/.bash_profile
  fi

  # Muat profil bash
  echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
  . $HOME/.bash_profile

  # Tampilkan nama node
  echo 'Nama node Anda: ' $nama_node

  # Perbarui sistem
  sudo apt-get update

  # Instal paket yang diperlukan
  sudo apt-get install -y ufw make clang pkg-config libssl-dev build-essential git 

  # Instal rust
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source $HOME/.cargo/env
  rustup update

  # Hapus direktori lama dan kloning baru
  cd $HOME
  rm -rf nym
  git clone https://github.com/nymtech/nym.git

  # Build dan pindahkan binary
  cd nym
  tag_terakhir=$(dapatkan_tag_terakhir)
  git checkout "$tag_terakhir"
  cargo build --release --bin nym-mixnode
  sudo mv target/release/nym-mixnode /usr/local/bin/

  # Inisialisasi node
  nym-mixnode init --id $nama_node --host $(curl ipinfo.io/ip)

  # Konfigurasi firewall
  sudo ufw allow 1789,1790,8000,22,80,443/tcp

  # Konfigurasi service
  sudo bash -c "cat > /etc/systemd/system/nym-mixnode.service" <<EOF
[Unit]
Description=Nym Mixnode

[Service]
User=$USER
ExecStart=/usr/local/bin/nym-mixnode run --id '$nama_node'
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
echo "Selamat! Mixnode Anda sedang berjalan. Saatnya untuk mendelegasikan token ke dalamnya dan mempromosikannya di antara teman-teman Anda."
echo "Pertahankan dan nikmati privasi yang disediakan NYM."
}

# Perbarui Node
perbarui_node() {
  echo "Mengambil informasi versi terbaru dari GitHub..."
  tag_terakhir=$(dapatkan_tag_terakhir)

  echo "Versi terbaru adalah $tag_terakhir. Apakah Anda ingin memperbarui ke versi ini? [Y/n]"
  read -r jawaban

  case ${jawaban:0:1} in
    y|Y )
        echo "Memperbarui ke versi $tag_terakhir..."
        cd $HOME/nym
        git fetch
        git checkout "$tag_terakhir"
        cargo build --release --bin nym-mixnode
        sudo mv target/release/nym-mixnode /usr/local/bin/
        sudo systemctl restart nym-mixnode
    ;;
    * )
        echo "Pembaruan dibatalkan."
    ;;
  esac
}

# Periksa status node
periksa_status() {
  status_node=$(sudo systemctl is-active nym-mixnode)
  if [ "$status_node" = "active" ]; then
    echo "Layanan Nym Mixnode aktif dan berjalan."
  else
    echo "Layanan Nym Mixnode tidak aktif."
  fi
}

# Hapus node
hapus_node() {
  sudo systemctl stop nym-mixnode
  sudo systemctl disable nym-mixnode
  sudo rm /usr/local/bin/nym-mixnode
  sudo rm /etc/systemd/system/nym-mixnode.service
  sudo systemctl daemon-reload
  rm -rf $HOME/nym
  echo "Node Nym berhasil dihapus."
}

# Menu aksi node
while true; do
  PS3='Silakan masukkan pilihan Anda: '
  pilihan=("Atur Node" "Periksa Node" "Perbarui Node" "Hapus Node" "Keluar")
  select opt in "${pilihan[@]}"
  do
      case $opt in
          "Atur Node")
              atur_node
              break
              ;;
          "Periksa Node")
              periksa_status
              break
              ;;
          "Perbarui Node")
              perbarui_node
              break
              ;;
          "Hapus Node")
              hapus_node
              break
              ;;
          "Keluar")
              break 2
              ;;
          *) echo "Pilihan tidak valid $REPLY";;
      esac
  done
done
