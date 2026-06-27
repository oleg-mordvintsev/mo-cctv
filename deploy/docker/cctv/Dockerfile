FROM alpine:latest

RUN apk add --no-cache ffmpeg nginx openssl bash

WORKDIR /app

COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY web/index.html /usr/share/nginx/html/index.html
COPY scripts/cleanup.sh /scripts/cleanup.sh
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh /scripts/cleanup.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
