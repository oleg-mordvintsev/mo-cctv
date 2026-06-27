
# MO-CCTV — Система видеонаблюдения

MO-CCTV — легковесная система видеонаблюдения на основе Docker.
Записывает RTSP потоки с IP-камер в сегментированные MP4, предоставляет веб-интерфейс для просмотра.

## Возможности

- 📹 Запись RTSP потоков через FFmpeg
- 🎥 Веб-интерфейс для просмотра видео
- 🔐 Базовая аутентификация (Basic Auth)
- 🗑️ Автоматическая очистка старых записей
- 📁 Организованное хранение с временными метками
- 🐳 Развертывание через Docker Swarm

## Установка

### Требования

- Docker и Docker Compose (режим Swarm)
- Git
- IP-камера с поддержкой RTSP

### Быстрая установка

1. **Клонирование репозитория**:
   ```bash
   git clone git@github.com:oleg-mordvintsev/mo-cctv.git .
   ```

2. **Инициализация**:
   ```bash
   ./init.sh
   ```

3. **Настройка окружения**:
   ```bash
   nano .env
   ```

4. **Пример конфигурации**:
   ```
   REGISTRY_URL=registry.mordvincev.ru
   RECORDS_PATH=./records
   NGINX_USER=admin
   NGINX_PASSWORD=ваш_безопасный_пароль
   RTSP_URL_1=rtsp://ip-вашей-камеры:554/stream
   CAMERA_PREFIX_1=входная_дверь
   SEGMENT_TIME=120
   HOURS_TO_KEEP=720
   ```

5. **Запуск**:
   ```bash
   ./start.sh
   ```

6. **Доступ**:
   Откройте `http://ваш-сервер:8888` в браузере.
   Учетные данные из `.env` файла.

## Управление

| Команда | Описание |
|---------|----------|
| `./start.sh` | Запуск в production (Swarm) |
| `./stop.sh` | Остановка |
| `./start-dev.sh` | Запуск в dev-режиме (foreground) |
| `./build-push.sh` | Сборка образа и публикация в registry |
| `./init.sh` | Повторная инициализация |

### Удаление пароля

```bash
rm nginx/.htpasswd && docker stack deploy -c docker-compose.yml mo-cctv
```
Для восстановления выполните `./init.sh`.

### Ручное создание директории записей

```bash
mkdir records && chown -R 1000:1000 records && chmod -R 755 records
```

## Детекция движения

Скрипт `motion-detection/detect.sh` анализирует MP4-записи на наличие движения
и вырезает отрезки с активностью.

```bash
cd records && ../motion-detection/detect.sh
```

Результат: папка `motion_clips/` с видеофрагментами.
