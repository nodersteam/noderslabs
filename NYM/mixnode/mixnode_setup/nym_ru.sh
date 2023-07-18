#!/bin/bash

# Проверка существования команды
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Проверка и установка curl при необходимости
if command_exists curl; then
  echo "Curl уже установлен"
else
  sudo apt-get update && sudo apt-get install curl -y
fi

# Проверка и установка jq при необходимости
if command_exists jq; then
  echo "jq уже установлен"
else
  sudo apt-get update && sudo apt-get install jq -y
fi

# Загрузка bash профиля
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi

# Получение последнего тега из релизов GitHub
get_latest_tag() {
  curl --silent "https://api.github.com/repos/nymtech/nym/releases" |
  jq -r '.[] | select(.name | test("Nym Binaries")) | .tag_name' |
  head -1
}

# Установка ноды
setup_node() {
  # Ввод имени ноды, если оно не существует
  if [ ! $node_name ]; then
    read -p "Введите имя узла: " node_name
    echo 'export node_name='\"${node_name}\" >> $HOME/.bash_profile
  fi

  # Загрузка bash профиля
  echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
  . $HOME/.bash_profile

  # Вывод имени ноды
  echo 'Ваше имя узла: ' $node_name

  # Обновление системы
  sudo apt-get update

  # Установка необходимых пакетов
  sudo apt-get install -y ufw make clang pkg-config libssl-dev build-essential git 

  # Установка rust
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source $HOME/.cargo/env
  rustup update

  # Удаление старого каталога и клонирование нового
  cd $HOME
  rm -rf nym
  git clone https://github.com/nymtech/nym.git

  # Сборка и перемещение бинарника
  cd nym
  latest_tag=$(get_latest_tag)
  git checkout "$latest_tag"
  cargo build --release --bin nym-mixnode
  sudo mv target/release/nym-mixnode /usr/local/bin/

  # Инициализация узла
  nym-mixnode init --id $node_name --host $(curl ifconfig.me)

  # Конфигурация брандмауэра
  sudo ufw allow 1789,1790,8000,22,80,443/tcp

  # Конфигурация сервиса
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
echo "Поздравляем! Ваша Mixnode установлена. Пришло время делегировать на нее токены и рассказать о ее преимуществах своим друзьям"
echo "Поддерживайте и наслаждайтесь конфиденциальностью в Интернете обеспеченной NYM"
}

# Обновление ноды
update_node() {
  echo "Извлечение последней информации о версии с GitHub..."
  latest_tag=$(get_latest_tag)

  echo "Последняя версия - $latest_tag. Хотите обновить до этой версии? [Y/n]"
  read -r answer

  case ${answer:0:1} in
    y|Y )
        echo "Обновление до версии $latest_tag..."
        cd $HOME/nym
        git fetch
        git checkout "$latest_tag"
        cargo build --release --bin nym-mixnode
        sudo mv target/release/nym-mixnode /usr/local/bin/
        sudo systemctl restart nym-mixnode
    ;;
    * )
        echo "Обновление отменено."
    ;;
  esac
}

# Проверка статуса ноды
check_status() {
  node_status=$(sudo systemctl is-active nym-mixnode)
  if [ "$node_status" = "active" ]; then
    echo "Сервис Nym Mixnode активен и работает."
  else
    echo "Сервис Nym Mixnode не активен."
  fi
}

# Удаление ноды
remove_node() {
  sudo systemctl stop nym-mixnode
  sudo systemctl disable nym-mixnode
  sudo rm /usr/local/bin/nym-mixnode
  sudo rm /etc/systemd/system/nym-mixnode.service
  sudo systemctl daemon-reload
  rm -rf $HOME/nym
  echo "Nym нода успешно удалена."
}

# Меню действий ноды
while true; do
  PS3='Пожалуйста, введите ваш выбор: '
  options=("Установка Ноды" "Проверка Ноды" "Обновление Ноды" "Удаление Ноды" "Выход")
  select opt in "${options[@]}"
  do
      case $opt in
          "Установка Ноды")
              setup_node
              break
              ;;
          "Проверка Ноды")
              check_status
              break
              ;;
          "Обновление Ноды")
              update_node
              break
              ;;
          "Удаление Ноды")
              remove_node
              break
              ;;
          "Выход")
              break 2
              ;;
          *) echo "Неверная опция $REPLY";;
      esac
  done
done
