#!/bin/bash

if [ ! -f .init-done ]; then
    ./init.sh
fi

docker compose -f docker-compose.yml -f docker-compose.override.yml up --build
