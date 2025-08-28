

docker-compose down && sleep 3 && docker-compose up -d




mkdir records && chmod 755 records




# Создайте папки для кэша nginx
mkdir -p nginx_cache nginx_temp && sudo chown -R 1000:1000 nginx_cache nginx_temp &&chmod -R 755 nginx_cache nginx_temp && sudo chown -R 1000:1000 records && chmod -R 755 records