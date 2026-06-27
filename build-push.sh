#!/bin/bash

if [ ! -f .init-done ]; then
    echo "Ошибка: проект не инициализирован. Сначала выполните ./init.sh"
    exit 1
fi

set -a; source .env; set +a

if [ -z "$REGISTRY_URL" ]; then
    echo "Ошибка: REGISTRY_URL не задан в .env"
    exit 1
fi

docker build \
    -t ${REGISTRY_URL}/mo-cctv/cctv:latest \
    -f deploy/docker/cctv/Dockerfile \
    .

docker push ${REGISTRY_URL}/mo-cctv/cctv:latest
echo "✓ Образ опубликован: ${REGISTRY_URL}/mo-cctv/cctv:latest"
