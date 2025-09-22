#!/bin/bash

if [ -f "nginx/.htpasswd" ]; then
    rm nginx/.htpasswd
    echo "✓ Пароль для web приложения удалён"
else
    echo "✓ Пароль для web приложения уже удалён"
fi

# grep -q "mo-cctv-" вернёт 0 при `echo $?` если найдено и 1 если не найдено
if docker ps --filter "name=mo-cctv-" --format "table {{.Names}}" | grep -q "mo-cctv-"; then
    ./restart.sh
fi
