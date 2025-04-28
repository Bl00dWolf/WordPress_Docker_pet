FROM ubuntu:25.04

# Переменные
ENV DATABASE_NAME="wd_press" \
    DATABASE_USER="wd_user" \
    DATABASE_PASSWORD="P@ssw0rd" \
    DATABASE_IP="127.0.0.1" \
    DB_CHARSET="utf8" \
    DB_TABLE_PREFIX="wp_"

# Установка необходимых пакетов
RUN apt-get update && \
    apt-get -y install nginx php8.4-common php8.4-bcmath php8.4-curl php8.4-imagick php8.4-intl php-json php8.4-mbstring php8.4-xml php8.4-zip php8.4-fpm php8.4-mysqli curl

# Установка wordpress 6.8
COPY files/wordpress-6.8_ru.tar.gz /home/ubuntu
WORKDIR /home/ubuntu
RUN tar -xvf wordpress-6.8_ru.tar.gz && \
    rm -rf /var/www/html/* && \
    mv /home/ubuntu/wordpress/* /var/www/html/ && \ 
    chown -R www-data:www-data /var/www/html/

# Перваночальная настройка wordpress
COPY files/wpconf.sh .
RUN chmod +x wpconf.sh && \
    ./wpconf.sh

# Конфигурация NGINX
RUN rm -rf /etc/nginx/sites-enabled/default
COPY files/nginx_wordpress /etc/nginx/sites-enabled/

# Конфигурация логирования php fpm
RUN echo '; Redirect error logs to stderr' >> /etc/php/8.4/fpm/pool.d/www.conf && \
    echo 'php_admin_value[error_log] = /dev/stderr' >> /etc/php/8.4/fpm/pool.d/www.conf && \
    echo 'php_admin_flag[log_errors] = on' >> /etc/php/8.4/fpm/pool.d/www.conf && \
    echo '; Optional: Redirect access logs to stdout' >> /etc/php/8.4/fpm/pool.d/www.conf && \
    echo 'access.log = /dev/stdout' >> /etc/php/8.4/fpm/pool.d/www.conf

# Удаляем лишнее
RUN rm -rf /home/ubuntu/wordpress/ && \
    rm -rf /home/ubuntu/wordpress-6.8_ru.tar.gz 

# Запуск сервисов
COPY files/services_start.sh .
RUN chmod +x services_start.sh
ENTRYPOINT ["./services_start.sh"]

EXPOSE 80
EXPOSE 443

