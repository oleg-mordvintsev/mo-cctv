#!/bin/bash

.stop.sh
rm nginx/.htpasswd
.start.sh

echo "✓ Пароль для web приложения удалён"