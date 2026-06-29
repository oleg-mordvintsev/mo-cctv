FROM alpine:latest

RUN apk add --no-cache ffmpeg nginx bash

WORKDIR /app

COPY deploy/docker/cctv/nginx/nginx.conf /etc/nginx/nginx.conf
COPY deploy/docker/cctv/web/index.html /usr/share/nginx/html/index.html
COPY deploy/docker/cctv/scripts/cleanup.sh /scripts/cleanup.sh
COPY deploy/docker/cctv/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh /scripts/cleanup.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
