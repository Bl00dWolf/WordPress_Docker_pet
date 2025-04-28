# Word Press pet проект

---
Этот проект был создан для изучения Docker, Docker file и Docker Compose.
Был взят за основу релиз WordPress 6.8. Под него написаны файлы конфигурации, подготовлена среда. Все необходимые файлы для билда лежат в files директории.

Docker file готов для сборки, он использует в основе образ ubuntu 25.05.
Docker compose содержит готовый для разворачивания набор WordPress из данного образа плюс MariaDB из dockerhub.

Для работы требуется доступ в интернет на период сборки образа из Dockerfile, а так же необходим доступ к https://api.wordpress.org/secret-key/1.1/salt/ для формирования ключей WordPress.

---
## Построение образа из Dockerfile
```bash
# Перейдите в нужную директорию предварительно
git clone https://github.com/Bl00dWolf/WordPress_Docker_pet.git

# Собрать образ my_wd версии 01 из docker file в текущем каталоге
docker build -t my_wd:01 .
```

## Пример запуска для `Docker`
```bash
docker run --name WordPress \
    -p 80:80 -p 443:443 \
    -e DATABASE_NAME=wdpress \
    -e DATABASE_USER=bl00dwolf \
    -e DATABASE_PASSWORD=bl00dwolf \
    -e DATABASE_IP=172.17.0.3 \
	-e DB_CHARSET=utf8 \
    -e DB_TABLE_PREFIX=wp_ \
    -v nginx_data:/etc/nginx/ \
    -v www_data:/var/www/ \
    -d my_wd:01
```

### Переменные:
`DATABASE_NAME` - необходимо указать название базы данных к которой будет подключаться WordPress.
`DATABASE_USER` - имя для доступа к базе данных.
`DATABASE_PASSWORD` - пароль для подключения к базе данных.
`DATABASE_IP` - IP \ DNS имя сервера базы данных.
`DB_CHARSET` - кодировка базы данных, по умолчанию `UTF8`. 
`DB_TABLE_PREFIX` - префикс таблиц, которые создаст и будет использовать WordPress в базе данных. По умолчанию `wp_`

### Директории (volumes)
Пожалуйста, обратите внимание, что в стандартном образе данные директории уже содержат в себе необходимые файлы для работы.
Если используется вариант `named volumes`, как в примере, то больше ничего делать не нужно.
Если будет использоваться вариант с `host volumes`, то данные сперва будет необходимо скопировать, пример описан дальше.

`nginx_data:/etc/nginx/` - директория с данными nginx
`www_data:/var/www/` - директория с данными WordPress

#### Директории пример с host volumes
```bash
# Запускаем временный контейнер, для копирования начальных данных
docker run --name WordPress_temp \
    -p 80:80 -p 443:443 \
    -e DATABASE_NAME=wdpress \
    -e DATABASE_USER=bl00dwolf \
    -e DATABASE_PASSWORD=bl00dwolf \
    -e DATABASE_IP=172.17.0.3 \
    -e DB_CHARSET=utf8 \
    -e DB_TABLE_PREFIX=wp_ \
    -d my_wd:01

# Копируем нужные первоначальные данные из контейнера на внешний хост
docker cp WordPress_temp:/etc/nginx/. /your_dir_for_nginx_data/
docker cp WordPress_temp:/var/www/. /your_dir_for_www_data/

# Останавливаем и удаляем временный контейнер
docker stop WordPress_temp
docker rm WordPress_temp

# Запускаем постоянный контейнер с host volumes
docker run --name WordPress \
    -p 80:80 -p 443:443 \
    -e DATABASE_NAME=wdpress \
    -e DATABASE_USER=bl00dwolf \
    -e DATABASE_PASSWORD=bl00dwolf \
    -e DATABASE_IP=172.17.0.3 \
	-e DB_CHARSET=utf8 \
    -e DB_TABLE_PREFIX=wp_ \
    -v /your_dir_for_www_data/:/etc/nginx/ \
    -v /your_dir_for_www_data/:/var/www/ \
    -d my_wd:01
```

## Пример запуска для Docker Compose

В проекте есть уже готовый файл, для работы данного образа в связке с MariaDB нужно только подставить верные данные:
```yml
services:
  web_wordpress:
    image: my_wd:01
    container_name: web_wordpress
    volumes:
      - wd_nginx_data:/etc/nginx/
      - wd_www_data:/var/www/
    ports:
      - '80:80'
      - '443:443'
    restart: unless-stopped
    environment:
      - DATABASE_NAME=wdpress
      - DATABASE_USER=bl00dwolf
      - DATABASE_PASSWORD=bl00dwolf
      - DATABASE_IP=db_mariadb
      - DB_CHARSET=utf8
      - DB_TABLE_PREFIX=wp_
    depends_on:
      - db_mariadb
    networks:
      - wordpress_net

  db_mariadb:
    image: mariadb:latest
    container_name: db_mariadb
    ports:
      - '3306:3306'
    restart: unless-stopped
    environment:
      - MARIADB_USER=bl00dwolf
      - MARIADB_PASSWORD=bl00dwolf
      - MARIADB_DATABASE=wdpress
      - MARIADB_ROOT_PASSWORD=bl00dwolf
    networks:
      - wordpress_net

networks:
  wordpress_net:
    name: wordpress_net
    driver: bridge

volumes:
  wd_nginx_data:
  wd_www_data:
```

`DATABASE_NAME` и `MARIADB_DATABASE` - указать имя базы данных, которая будет создана и использована WordPress.
`DATABASE_USER` и `MARIADB_USER` - указать имя пользователя, который будет создан и использован WordPress для доступа к базе данных.
`DATABASE_PASSWORD` и `MARIADB_PASSWORD` - указать пароль пользователя, который будет создан и использован WordPress для доступа к базе данных.
`DATABASE_IP` - оставить как есть, будет использован IP запущенного контейнера с MariaDB. Используется для подключения WordPress к базе данных.
`DB_CHARSET` - кодировка базы данных.
`DB_TABLE_PREFIX` - префикс таблиц WordPress
`MARIADB_ROOT_PASSWORD` - рутовый пароль для MariaDB.

Далее запустить `docker compose up` для запуска контейнеров. 

---

В браузере перейти по HTTP 80 порту для завершения конфигурации WordPress - задать логин, пароль, емейл, имя сайта. 

Готово!

## Описание файлов проекта

`dockerfile` - файл для создания образа для docker. Использует файлы из `files` директории.

`docker-compose.yml` - файл `docker compose` для запуска контейнера и БД данного проекта. 

`files/nginx_wordpress` - файл конфигурации `nginx` для корректной работы с `wordpress` и выводом логов в `docker`.

`files/services_start.sh` - файл использующийся контейнером WordPress для своего запуска. Прописывает конфигурацию, запускает `nginx` и `php-fpm`

`files/wordpress-6.8_ru.tar.gz` - архив с релизом WordPress 6.8. Можно заменить в `dockerfile` директиву с данного образа, на использования curl скачку актуального, если если требуется: `RUN curl https://ru.wordpress.org/latest-ru_RU.zip`

`files/wpconf.sh` - основной файл конфигурации WordPress, содержит данные с использованием переменных среды для работы WordPress и первого запуска.
