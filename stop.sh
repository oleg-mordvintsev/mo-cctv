#!/bin/bash

docker-compose down
if [ ! -f "nginx/.htpasswd" ]; then
    rm -R -f nginx/.htpasswd
fi
sleep 3
echo "✓ Приложение остановлено"