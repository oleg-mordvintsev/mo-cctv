#!/bin/bash
# MO-CCTV Детектор движения
# Анализирует MP4-записи из текущей директории,
# находит периоды с движением и вырезает клипы в motion_clips/
#
# Запуск: cd /путь/к/records && ../motion-detection/ts.sh

OUTPUT_DIR="motion_clips"
SCREENSHOTS_DIR="motion_screenshots"
mkdir -p "$OUTPUT_DIR"
mkdir -p "$SCREENSHOTS_DIR"

for file in *.mp4; do
    echo "🔍 Анализируем: $file"
    
    if [ ! -f "$file" ] || [ ! -r "$file" ]; then
        echo "❌ Файл недоступен"
        continue
    fi
    
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
    if [ -z "$duration" ] || [ $(echo "$duration < 10" | bc -l 2>/dev/null || echo 1) -eq 1 ]; then
        echo "❌ Неверная длительность"
        continue
    fi
    
    echo "📏 Длительность: $duration секунд"
    
    # Очищаем папку скриншотов
    rm -rf "$SCREENSHOTS_DIR/${file%.mp4}"
    mkdir -p "$SCREENSHOTS_DIR/${file%.mp4}"
    
    # Создаем скриншоты
    echo "📸 Создаем скриншоты..."
    ffmpeg -i "$file" -r 1 -q:v 2 "$SCREENSHOTS_DIR/${file%.mp4}/frame_%04d.jpg" 2>/dev/null
    
    frame_count=$(find "$SCREENSHOTS_DIR/${file%.mp4}" -name "frame_*.jpg" | wc -l)
    echo "📊 Создано кадров: $frame_count"
    
    > /tmp/motion_periods.txt
    motion_threshold=6
    
    # Используем первый кадр как эталон
    reference_frame="$SCREENSHOTS_DIR/${file%.mp4}/frame_0001.jpg"
    reference_size=$(stat -c%s "$reference_frame" 2>/dev/null || echo "0")
    
    echo "🎯 Анализируем движение (порог: ${motion_threshold}%)..."
    
    # Собираем ВСЕ данные о движении
    > /tmp/all_motion_data.txt
    for i in $(seq 1 $frame_count); do
        frame_file=$(printf "$SCREENSHOTS_DIR/${file%.mp4}/frame_%04d.jpg" $i)
        
        if [ ! -f "$frame_file" ]; then
            continue
        fi
        
        current_size=$(stat -c%s "$frame_file" 2>/dev/null || echo "0")
        size_diff_percent=0
        
        if [ "$reference_size" -gt 0 ]; then
            size_diff=$((current_size - reference_size))
            size_diff_abs=${size_diff#-}
            size_diff_percent=$((size_diff_abs * 100 / reference_size))
        fi
        
        timestamp=$((i - 1))
        echo "$timestamp $size_diff_percent" >> /tmp/all_motion_data.txt
    done

    # ПРОСТАЯ и ПРАВИЛЬНАЯ логика обнаружения периодов
    echo "🔄 Определяем периоды движения..."
    
    # Сначала получим список всех секунд с движением
    > /tmp/motion_seconds.txt
    while read -r timestamp percent; do
        if [ $percent -ge $motion_threshold ]; then
            echo "$timestamp" >> /tmp/motion_seconds.txt
        fi
    done < /tmp/all_motion_data.txt

    # Теперь группируем последовательные секунды в периоды
    if [ -s /tmp/motion_seconds.txt ]; then
        periods=()
        current_period=()
        
        while read -r second; do
            if [ ${#current_period[@]} -eq 0 ]; then
                current_period=($second)
            elif [ $second -eq $((${current_period[-1]} + 1)) ]; then
                current_period+=($second)
            else
                # Сохраняем текущий период и начинаем новый
                if [ ${#current_period[@]} -ge 3 ]; then  # минимум 3 секунды
                    start=${current_period[0]}
                    end=${current_period[-1]}
                    duration=$((end - start + 1))
                    periods+=("$start $duration")
                    echo "📈 Период: ${start}-${end}с (${duration}с)"
                fi
                current_period=($second)
            fi
        done < /tmp/motion_seconds.txt
        
        # Добавляем последний период
        if [ ${#current_period[@]} -ge 3 ]; then
            start=${current_period[0]}
            end=${current_period[-1]}
            duration=$((end - start + 1))
            periods+=("$start $duration")
            echo "📈 Период: ${start}-${end}с (${duration}с)"
        fi
        
        # Сохраняем периоды в файл
        for period in "${periods[@]}"; do
            echo "$period" >> /tmp/motion_periods.txt
        done
    fi

    # ОТЛАДКА: покажем что в файле
    echo "🔍 Содержимое файла периодов:"
    cat /tmp/motion_periods.txt
    
    # Создаем видео-отрезки - ИСПРАВЛЕННАЯ ВЕРСИЯ
    event_count=$(wc -l < /tmp/motion_periods.txt 2>/dev/null || echo 0)
    echo "📊 Найдено периодов движения: $event_count"
    
    if [ $event_count -gt 0 ]; then
        counter=0
        # СОХРАНИМ периоды в массив, чтобы избежать проблем с чтением из файла
        periods_array=()
        while IFS= read -r line; do
            periods_array+=("$line")
        done < /tmp/motion_periods.txt
        
        # Теперь обрабатываем массив вместо чтения из файла
        for period_line in "${periods_array[@]}"; do
            # Разбираем строку на переменные
            motion_start=$(echo "$period_line" | cut -d' ' -f1)
            motion_duration=$(echo "$period_line" | cut -d' ' -f2)
            
            echo "📖 Обрабатываем период: start=$motion_start duration=$motion_duration"
            
            # Добавляем буфер: 3 секунды до и 3 секунды после
            start_time=$((motion_start - 3))
            [ $start_time -lt 0 ] && start_time=0
            
            # Длительность отрезка = длительность движения + 5 секунд (2 до + 3 после)
            segment_duration=$((motion_duration + 6))
            
            filename="${file%.mp4}"
            output_file="$OUTPUT_DIR/${filename}_motion_${motion_start}s_${segment_duration}s.mp4"
            
            echo "🎬 Создаем отрезок $((counter + 1)): с ${start_time}с длительность ${segment_duration}с"
            echo "   Движение: ${motion_start}-$((motion_start + motion_duration - 1))с"
            
            # САМАЯ ПРОСТАЯ КОМАНДА FFMPEG
            ffmpeg -i "$file" -ss "$start_time" -t "$segment_duration" -c copy -y "$output_file" 2>/dev/null
            
            if [ -f "$output_file" ] && [ -s "$output_file" ]; then
                echo "✅ Создан: $(basename "$output_file")"
                counter=$((counter + 1))
            else
                echo "❌ Ошибка создания"
            fi
        done
        
        echo "✅ Итог: создано $counter отрезков"
    else
        echo "❌ Движение не обнаружено"
    fi
    
    # УДАЛЯЕМ СКРИНШОТЫ после анализа этого файла
    echo "🗑️ Удаляем скриншоты для $file"
    rm -rf "$SCREENSHOTS_DIR/${file%.mp4}"
    
    echo "---"
    rm -f /tmp/motion_periods.txt /tmp/all_motion_data.txt /tmp/motion_seconds.txt
done

echo "🎉 Готово! Всего отрезков: $(find "$OUTPUT_DIR" -name "*.mp4" 2>/dev/null | wc -l)"