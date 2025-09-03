#!/bin/bash

docker-compose down && sleep 3 && docker-compose up -d

echo "✓ приложение перезапущено"