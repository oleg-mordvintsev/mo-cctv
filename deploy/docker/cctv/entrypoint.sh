#!/bin/bash
set -e

(
    while true; do
        /scripts/cleanup.sh
        sleep 3600
    done
) &

(
    while true; do
        ffmpeg \
            -timeout 5000000 \
            -rtsp_transport tcp \
            -i "${RTSP_URL_1}" \
            -c:v copy \
            -c:a aac -b:a 32k -ac 1 \
            -f segment \
            -segment_time 300 \
            -segment_format mp4 \
            -reset_timestamps 1 \
            -strftime 1 \
            -avoid_negative_ts make_non_negative \
            "/records/${CAMERA_PREFIX_1}_%Y-%m-%d_%H-%M-%S.mp4"
        sleep 5
    done
) &

exec nginx -g 'daemon off;'
