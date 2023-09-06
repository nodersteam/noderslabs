#!/usr/bin/env bash

docker-safe() {
  if ! command -v docker &>/dev/null; then
    echo "docker is not installed on this machine"
    exit 1
  fi

  if ! docker "$@"; then
    echo "Trying again with sudo..."
    sudo docker "$@"
  fi
}

# Получаем ID контейнера с образом local-dashboard
CONTAINER_ID=$(docker-safe ps -qf "ancestor=local-dashboard")

if [ -z "$CONTAINER_ID" ]; then
    echo "Container with the image local-dashboard not found."
    exit 1
fi

# Выводим 100 последних строк логов контейнера
docker-safe logs --tail 100 "$CONTAINER_ID"