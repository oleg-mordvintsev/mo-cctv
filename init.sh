#!/bin/bash

# MO-CCTV Инициализация

echo "Синхронизация с репозиторием..."
git pull --ff-only

set -e

if [ -f ".init-done" ]; then
    read -p "Файл .init-done найден. Запустить инициализацию заново? (y/N): " confirm
    case "$confirm" in
        [yY]) ;;
        *) exit 0 ;;
    esac
fi

echo "=== Инициализация MO-CCTV ==="

# Проверка установленного Docker
if ! command -v docker &> /dev/null; then
    echo "ОШИБКА: Docker не установлен. Пожалуйста, сначала установите Docker."
    echo "Инструкции по установке: https://docs.docker.com/engine/install/"
    exit 1
fi

# Проверка Docker Compose
if ! docker compose version &> /dev/null; then
    echo "ОШИБКА: Docker Compose не установлен. Пожалуйста, сначала установите Docker Compose."
    exit 1
fi

echo "✓ Docker и Docker Compose установлены."

# Создание необходимых директорий
echo "Создание необходимых директорий и установка прав..."
mkdir -p records nginx
chown -R 1000:1000 records nginx 2>/dev/null || true
chmod -R 755 records nginx

# Создание файла окружения если не существует
if [ ! -f ".env" ]; then
    echo "Создание .env файла..."
    cat > .env << EOF
# MO-CCTV Конфигурация окружения
REGISTRY_URL=registry.mordvincev.ru
RECORDS_PATH=./records
SEGMENT_TIME=120

NGINX_USER=admin
NGINX_PASSWORD=$(openssl rand -base64 12)

# Сколько часов храним видео? (30 дней = 720 часов)
HOURS_TO_KEEP=720

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

if [ -f ".env" ]; then
    NGINX_USER=$(grep -E "^NGINX_USER=" .env | cut -d '=' -f2)
    NGINX_PASSWORD=$(grep -E "^NGINX_PASSWORD=" .env | cut -d '=' -f2)

    NGINX_USER=$(echo $NGINX_USER | sed "s/['\"]//g")
    NGINX_PASSWORD=$(echo $NGINX_PASSWORD | sed "s/['\"]//g")

    echo "Найдены учетные данные: пользователь=$NGINX_USER"
fi

if [ -n "$NGINX_USER" ] && [ -n "$NGINX_PASSWORD" ]; then
    echo "$NGINX_USER:$(openssl passwd -5 "$NGINX_PASSWORD")" > nginx/.htpasswd
    echo "✓ Файл .htpasswd создан с помощью openssl"

    chmod 644 nginx/.htpasswd
    chown 1000:1000 nginx/.htpasswd 2>/dev/null || true
else
    echo "⚠️  Не удалось прочитать учетные данные из переменных окружения"
    echo "Убедитесь, что NGINX_USER и NGINX_PASSWORD установлены"
    echo "Или создайте файл вручную:"
    echo "echo 'admin:\$(openssl passwd -5 ваш_пароль)' > nginx/.htpasswd"
fi

# Установка прав на скрипты
chmod +x start.sh stop.sh start-dev.sh build-push.sh 2>/dev/null || true

touch .init-done

if ! grep -qxF '.init-done' .gitignore 2>/dev/null; then
    echo '.init-done' >> .gitignore
fi

echo ""
echo "=== Инициализация завершена ==="
echo ""
echo "Следующие шаги:"
echo "1. Просмотрите и отредактируйте .env файл:"
echo "   - Установите REGISTRY_URL (если используете registry)"
echo "   - Установите RECORDS_PATH (путь к директории с видео)"
echo "   - Установите SEGMENT_TIME (длительность сегмента в секундах)"
echo "   - Установите HOURS_TO_KEEP (сколько часов хранить записи)"
echo "   - Установите RTSP_URL_1 (адрес камеры)"
echo "   - Установите CAMERA_PREFIX_1 (префикс имени камеры)"
echo ""
echo "2. Запустите систему:"
echo "   ./start.sh"
echo ""
echo "3. Откройте веб-интерфейс:"
echo "   http://ваш-сервер:8888"
echo ""
