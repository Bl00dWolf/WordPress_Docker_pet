#!/bin/bash
/home/ubuntu/wpconf.sh
/usr/sbin/nginx -g "daemon off;" &
/usr/sbin/php-fpm8.4 --nodaemonize
