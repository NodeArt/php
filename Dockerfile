FROM composer:latest
FROM php:7.2.13-fpm-alpine3.8

# Environments
ENV PHP_TIMEZONE UTC
ENV PHP_MEMORY_LIMIT 512M
ENV PHP_MAX_UPLOAD 50M
ENV PHP_MAX_FILE_UPLOAD 200
ENV PHP_MAX_EXECUTION_TIME 30
ENV PHP_MAX_POST 100M
ENV PHP_DISPLAY_ERRORS On
ENV PHP_LOG_ERRORS On
ENV PHP_ENABLE_XDEBUG 0
ENV PHP_EXPOSE_PHP On
ENV PHPIZE_DEPS autoconf dpkg-dev dpkg file g++ gcc libc-dev make pkgconf re2c git
ENV COMPOSER_ALLOW_SUPERUSER 1

RUN apk upgrade --no-cache && apk add --no-cache bash imagemagick nano shadow tzdata

# Preparing
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS coreutils \
\
# PHP GD
&& apk add --no-cache libpng libjpeg-turbo freetype libxpm \
&& apk add --no-cache --virtual .build-deps libpng-dev libjpeg-turbo-dev libxpm-dev freetype-dev \
&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-xpm-dir=/usr/include/ \
&& docker-php-ext-install gd \
\
# PHP Zip
&& apk add --no-cache libzip \
&& apk add --no-cache --virtual .build-deps zlib-dev \
&& docker-php-ext-configure zip \
&& docker-php-ext-install zip \
\
# PHP mysqli
&& docker-php-ext-install mysqli \
\
# PHP pdo_mysql
&& docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
&& docker-php-ext-install pdo_mysql \
\
# PHP gettext
&& apk add --no-cache gettext gettext-libs gettext-asprintf \
&& apk add --no-cache --virtual .build-deps gettext-dev \
&& docker-php-ext-install gettext \
\
# PHP bcmath
&& docker-php-ext-install bcmath \
\
# PHP mcrypt
&& apk add --no-cache libmcrypt \
&& apk add --no-cache --virtual .build-deps libmcrypt-dev \
&& yes '' | pecl install -f mcrypt \
&& docker-php-ext-enable mcrypt \
\
# PHP intl
&& apk add --no-cache icu \
&& apk add --no-cache --virtual .build-deps icu-dev \
&& docker-php-ext-install intl \
\
# PHP opcache
&& docker-php-ext-install opcache \
\
# PHP memcached
&& apk add --no-cache libmemcached \
&& apk add --no-cache --virtual .build-deps libmemcached-dev zlib-dev cyrus-sasl-dev \
&& yes '' | pecl install memcached \
&& docker-php-ext-enable memcached \
\
# PHP xdebug
&& yes '' | pecl install xdebug \
&& docker-php-ext-enable xdebug \
\
# PHP redis
&& yes '' | pecl install redis \
&& docker-php-ext-enable redis \
\
# PHP imagick
&& apk add --no-cache imagemagick-libs jpegoptim \
&& apk add --no-cache --virtual .build-deps imagemagick-dev \
&& yes '' | pecl install imagick \
&& docker-php-ext-enable imagick \
\
# PHP ioncube
&& wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
&& tar -xvvzf ioncube_loaders_lin_x86-64.tar.gz \
&& mv ioncube/ioncube_loader_lin_7.2.so /usr/local/lib/php/extensions/* \
&& rm -Rf ioncube_loaders_lin_x86-64.tar.gz ioncube \
&& docker-php-ext-enable ioncube_loader_lin_7.2 \
\
#MaxMind-DB-Reader-php
&& apk add --no-cache libmaxminddb \
&& apk add --no-cache --virtual .build-deps libmaxminddb-dev \
&& git clone https://github.com/maxmind/MaxMind-DB-Reader-php.git \
&& ( \
  cd MaxMind-DB-Reader-php/ext \
  && phpize \
  && ./configure \
  && make \
  && make install \
) \
&& rm -r MaxMind-DB-Reader-php \
&& docker-php-ext-enable maxminddb \
\
#Maxmind GEOIP Database
&& rm -rf /usr/local/share/GeoIP/ && wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.mmdb.gz \
  && gunzip -f GeoLite2-Country.mmdb.gz \
  && ( \
    mkdir -p /usr/local/share/GeoIP/ \
    && cp -f GeoLite2-Country.mmdb /usr/local/share/GeoIP/ \
  ) \
  && rm -rf GeoLite2-Country.mmdb \
\
#Maxmind GEOIP Database
&& wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz \
  && gunzip -f GeoLite2-City.mmdb.gz \
  && ( \
    mkdir -p /usr/local/share/GeoIP/ \
    && cp -f GeoLite2-City.mmdb /usr/local/share/GeoIP/ \
  ) \
  && rm -rf GeoLite2-City.mmdb \
\
# Cleaning
&& apk del .build-deps

# Set config parameters
RUN apk add --no-cache --virtual .temp py-pip \
  && pip install --no-cache-dir crudini \
  && crudini --set $PHP_INI_DIR/php.ini Date date.timezone '${PHP_TIMEZONE}' \
  && crudini --set $PHP_INI_DIR/php.ini PHP memory_limit '${PHP_MEMORY_LIMIT}' \
  && crudini --set $PHP_INI_DIR/php.ini PHP display_errors '${PHP_DISPLAY_ERRORS}' \
  && crudini --set $PHP_INI_DIR/php.ini PHP log_errors '${PHP_LOG_ERRORS}' \
  && crudini --set $PHP_INI_DIR/php.ini PHP upload_max_filesize '${PHP_MAX_UPLOAD}' \
  && crudini --set $PHP_INI_DIR/php.ini PHP max_file_uploads '${PHP_MAX_FILE_UPLOAD}' \
  && crudini --set $PHP_INI_DIR/php.ini PHP post_max_size '${PHP_MAX_POST}' \
  && crudini --set $PHP_INI_DIR/php.ini PHP expose_php '${PHP_EXPOSE_PHP}' \
  && crudini --set $PHP_INI_DIR/php.ini PHP max_execution_time '${PHP_MAX_EXECUTION_TIME}' \
  && crudini --set $PHP_INI_DIR/php.ini PHP cgi.fix_pathinfo 0 \
  && crudini --set $PHP_INI_DIR/../php-fpm.d/www.conf www listen 9000 \
  && crudini --set $PHP_INI_DIR/../php-fpm.d/www.conf www pm.max_children 20 \
  && crudini --set $PHP_INI_DIR/../php-fpm.d/www.conf www env[DB_1_ENV_MYSQL_DATABASE] 'DB_1_ENV_MYSQL_DATABASE' \
  && crudini --set $PHP_INI_DIR/../php-fpm.d/www.conf www env[DB_1_ENV_MYSQL_USER] '$DB_1_ENV_MYSQL_USER' \
  && crudini --set $PHP_INI_DIR/../php-fpm.d/www.conf www env[DB_1_ENV_MYSQL_PASSWORD] '$DB_1_ENV_MYSQL_PASSWORD' \
  && sed -i 's/^zend_extension/;zend_extension/' $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini \
  && sed -i "\$i if [ \"\$PHP_ENABLE_XDEBUG\" -eq \"1\" ]; then" /usr/local/bin/docker-php-entrypoint \
  && sed -i "\$i \  sed -i \'s/^;zend_extension/zend_extension/\' $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini" /usr/local/bin/docker-php-entrypoint \
  && sed -i "\$i fi\n" /usr/local/bin/docker-php-entrypoint \
  && apk del .temp \
  && mkdir /etc/periodic/1min \
  && sed -i '/^$/d' /etc/crontabs/root \
  && echo "*       *       *       *       *       run-parts /etc/periodic/1min" >> /etc/crontabs/root \
  && sed -i -e '$a\' /etc/crontabs/root

#Composer
COPY --from=0 /usr/bin/composer /usr/bin/composer
RUN composer global require "hirak/prestissimo:^0.3" --prefer-dist --no-progress --no-suggest --classmap-authoritative

