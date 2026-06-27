#!/bin/sh

# Путь к папке с записями
RECORDS_DIR="/records"

# Сколько часов хранить записи?
HOURS_TO_KEEP="${HOURS_TO_KEEP:-72}"

# Удаляем файлы старше указанного количества часов
find "$RECORDS_DIR" -name "*.mp4" -type f -mmin +$(($HOURS_TO_KEEP * 60)) -exec rm -f {} \;