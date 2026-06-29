#!/bin/bash

if [ ! -f .init-done ]; then
    ./init.sh
fi

set -a; [ -f .env ] && source .env; set +a

if [ -z "${RECORDS_PATH}" ]; then
    echo "ОШИБКА: RECORDS_PATH не задан."
    echo "Укажите путь к директории с видео в .env файле."
    echo "Пример: RECORDS_PATH=./records"
    exit 1
fi

docker stack deploy --with-registry-auth -c docker-compose.yml srv-cctv
echo "✓ Приложение запущено в режиме Swarm"
