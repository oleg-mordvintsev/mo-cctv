#!/bin/bash

if [ ! -f .init-done ]; then
    ./init.sh
fi

docker stack deploy -c docker-compose.yml mo-cctv
echo "✓ Приложение запущено в режиме Swarm"
