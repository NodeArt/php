# PHP
Version based on official 7.2 alpine, runned by www-data (82)

### [image on DockerHub](https://hub.docker.com/r/nodeartio/php/)

## supported environment variables

ENV TIMEZONE - Default UTC

ENV PHP_MEMORY_LIMIT - Default 512M

ENV MAX_UPLOAD - Default 50M

ENV PHP_MAX_FILE_UPLOAD - Default 200

ENV PHP_MAX_POST - Default 100M

ENV PHP_DISPLAY_ERRORS - Default On (enabled), acceptable var On,Off

ENV PHP_LOG_ERRORS - Default On (enabled), acceptable var On,Off

PHP_ENABLE_XDEBUG - Default 0 (disabled), acceptable var 0,1

PHP_EXPOSE_PHP - Default On (enabled), acceptable var On,Off

## Modules Added
### modules added and compiled
GD, Zip, mysqli, pdo_mysql, gettext, bcmath, mcrypt, intl, opcache, memcached, xdebug, redis, imagick
### modules will be compiled on start
MaxMind-DB-Reader-php

