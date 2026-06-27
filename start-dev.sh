#!/bin/bash

if [ ! -f .init-done ]; then
    ./init.sh
fi

docker compose up --build
