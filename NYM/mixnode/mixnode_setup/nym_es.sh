#!/bin/bash

# Verificar si el comando existe
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Verificar e instalar curl si es necesario
if command_exists curl; then
  echo "Curl ya está instalado"
else
  sudo apt-get update && sudo apt-get install curl -y
fi

# Verificar e instalar jq si es necesario
if command_exists jq; then
  echo "jq ya está instalado"
else
  sudo apt-get update && sudo apt-get install jq -y
fi

# Cargar perfil de bash
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi

# Obtener la última etiqueta de los lanzamientos de GitHub
get_latest_tag() {
  curl --silent "https://api.github.com/repos/nymtech/nym/releases" |
  jq -r '.[] | select(.name | test("Nym Binaries")) | .tag_name' |
  head -1
}

# Configuración de nodo
setup_node() {
  # Introducir el nombre del nodo si no existe
  if [ ! $node_name ]; then
    read -p "Introduce el nombre del nodo: " node_name
    echo 'export node_name='\"${node_name}\" >> $HOME/.bash_profile
  fi

  # Cargar perfil de bash
  echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
  . $HOME/.bash_profile

  # Mostrar el nombre del nodo
  echo 'Tu nombre de nodo: ' $node_name

  # Actualizar sistema
  sudo apt-get update

  # Instalar paquetes necesarios
  sudo apt-get install -y ufw make clang pkg-config libssl-dev build-essential git 

  # Instalar rust
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source $HOME/.cargo/env
  rustup update

  # Eliminar directorio antiguo y clonar uno nuevo
  cd $HOME
  rm -rf nym
  git clone https://github.com/nymtech/nym.git

  # Compilar y mover el binario
  cd nym
  latest_tag=$(get_latest_tag)
  git checkout "$latest_tag"
  cargo build --release --bin nym-mixnode
  sudo mv target/release/nym-mixnode /usr/local/bin/

  # Inicializar nodo
  nym-mixnode init --id $node_name --host $(curl ipinfo.io/ip)

  # Configurar firewall
  sudo ufw allow 1789,1790,8000,22,80,443/tcp

  # Configurar servicio
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
echo "¡Felicidades! Tu mixnode está funcionando. Es hora de delegar tokens en él y promocionarlo entre tus amigos."
echo "Apoya y valora la privacidad proporcionada por NYM."
}

# Actualización del nodo
update_node() {
  echo "Obteniendo la información más reciente de la versión de GitHub..."
  latest_tag=$(get_latest_tag)

  echo "La versión más reciente es $latest_tag. ¿Quieres actualizar a esta versión? [Y/n]"
  read -r answer

  case ${answer:0:1} in
    y|Y )
        echo "Actualizando a la versión $latest_tag..."
        cd $HOME/nym
        git fetch
        git checkout "$latest_tag"
        cargo build --release --bin nym-mixnode
        sudo mv target/release/nym-mixnode /usr/local/bin/nym-mixnode
        sudo systemctl restart nym-mixnode
    ;;
    * )
        echo "Actualización cancelada."
    ;;
  esac
}

# Verificar el estado del nodo
check_status() {
  node_status=$(sudo systemctl is-active nym-mixnode)
  if [ "$node_status" = "active" ]; then
    echo "El servicio Nym Mixnode está activo y en funcionamiento."
  else
    echo "El servicio Nym Mixnode está inactivo."
  fi
}

# Eliminación del nodo
remove_node() {
  sudo systemctl stop nym-mixnode
  sudo systemctl disable nym-mixnode
  sudo rm /usr/local/bin/nym-mixnode
  sudo rm /etc/systemd/system/nym-mixnode.service
  sudo systemctl daemon-reload
  rm -rf $HOME/nym
  echo "El nodo Nym se ha eliminado correctamente."
}

# Menú de acciones del nodo
while true; do
  PS3='Por favor, introduce tu elección: '
  options=("Configurar Nodo" "Verificar Nodo" "Actualizar Nodo" "Eliminar Nodo" "Salir")
  select opt in "${options[@]}"
  do
      case $opt in
          "Configurar Nodo")
              setup_node
              break
              ;;
          "Verificar Nodo")
              check_status
              break
              ;;
          "Actualizar Nodo")
              update_node
              break
              ;;
          "Eliminar Nodo")
              remove_node
              break
              ;;
          "Salir")
              break 2
              ;;
          *) echo "Opción inválida $REPLY";;
      esac
  done
done
