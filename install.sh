#!/bin/bash

# MO-CCTV Установщик

set -e # Выход при ошибке

echo "=== Установка MO-CCTV ==="

# Проверка установленного Docker
if ! command -v docker &> /dev/null; then
    echo "ОШИБКА: Docker не установлен. Пожалуйста, сначала установите Docker."
    echo "Инструкции по установке: https://docs.docker.com/engine/install/"
    exit 1
fi

# Проверка Docker Compose
if ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
    echo "ОШИБКА: Docker Compose не установлен. Пожалуйста, сначала установите Docker Compose."
    exit 1
fi

echo "✓ Docker и Docker Compose установлены."

# Клонирование или обновление репозитория
if [ -d ".git" ]; then
    echo "✓ Репозиторий уже клонирован. Обновление..."
    git pull
else
    echo "Клонирование репозитория..."
    git clone git@github.com:oleg-mordvintsev/mo-cctv.git .
fi

# Создание необходимых директорий
echo "Создание необходимых директорий и установка прав..."
mkdir -p records nginx/cache nginx/temp scripts web
chown -R 1000:1000 records nginx/cache nginx/temp
chmod -R 755 records nginx/cache nginx/temp scripts

# Установка прав на скрипт очистки
echo "Установка прав на скрипты..."
chmod +x scripts/cleanup.sh
chmod +x start.sh
chmod +x stop.sh
chmod +x restart.sh
chmod +x noPass.sh

# Создание файла окружения для учетных данных если не существует
if [ ! -f ".env" ]; then
    echo "Создание .env файла для учетных данных..."
    cat > .env << EOF
# MO-CCTV Конфигурация окружения
NGINX_USER=admin
NGINX_PASSWORD=$(openssl rand -base64 12)

# Сколько часов храним видео?
HOURS_TO_KEEP=168

# Настройки камеры №1
RTSP_URL_1=rtsp://192.168.0.121:554/0/av1
CAMERA_PREFIX_1=ЛифтовойХолл

# Настройки камеры №2
#RTSP_URL_2=rtsp://server:554
#CAMERA_PREFIX_2=SecondCam
EOF
    echo "✓ Создан .env файл со случайным паролем"
    echo "Пожалуйста, проверьте и отредактируйте .env файл для вашей конфигурации!"
else
    echo "✓ .env файл уже существует"
fi

# Загрузка переменных окружения
if [ -f ".env" ]; then
    set -a
    source .env
    set +a
fi

# Настройка базовой аутентификации nginx
echo "Настройка базовой аутентификации nginx..."

# Читаем переменные из .env файла
if [ -f ".env" ]; then
    # Загружаем переменные из .env
    NGINX_USER=$(grep -E "^NGINX_USER=" .env | cut -d '=' -f2)
    NGINX_PASSWORD=$(grep -E "^NGINX_PASSWORD=" .env | cut -d '=' -f2)

    # Убираем кавычки если есть
    NGINX_USER=$(echo $NGINX_USER | sed "s/['\"]//g")
    NGINX_PASSWORD=$(echo $NGINX_PASSWORD | sed "s/['\"]//g")

    echo "Найдены учетные данные: пользователь=$NGINX_USER"
fi

# Создание файла аутентификации
if [ -n "$NGINX_USER" ] && [ -n "$NGINX_PASSWORD" ]; then
    # Всегда используем openssl для единообразия
    echo "$NGINX_USER:$(openssl passwd -5 "$NGINX_PASSWORD")" > nginx/.htpasswd
    echo "✓ Файл .htpasswd создан с помощью openssl"

    # Устанавливаем права доступа
    chmod 644 nginx/.htpasswd
    chown 1000:1000 nginx/.htpasswd 2>/dev/null || true
else
    echo "⚠️  Не удалось прочитать учетные данные из переменных окружения"
    echo "Убедитесь, что NGINX_USER и NGINX_PASSWORD установлены"
    echo "Или создайте файл вручную:"
    echo "echo 'admin:\$(openssl passwd -5 ваш_пароль)' > nginx/.htpasswd"
fi

echo ""
echo "=== Установка завершена ==="
echo ""
echo "Следующие шаги:"
echo "1. Просмотрите и отредактируйте .env файл:"
echo "   - Установите ваш адрес камеры RTSP_URL_1"
echo "   - Установите префикс названия камеры CAMERA_PREFIX_1"
echo "   - Измените NGINX_USER и NGINX_PASSWORD при необходимости"
echo ""
echo "2. Запустите систему:"
echo "   ./start.sh"
echo ""
echo "3. Откройте веб-интерфейс:"
echo "   http://ваш-сервер:8888"
echo ""
if [ -f ".env" ] && [ -n "$NGINX_USER" ] && [ -n "$NGINX_PASSWORD" ]; then
    echo "   Логин: $NGINX_USER"
    echo "   Пароль: $NGINX_PASSWORD"
else
    echo "   Логин и пароль смотрите в .env файле"
fi
echo ""
echo "4. Для просмотра логов:"
echo "   docker-compose logs -f"