FROM php:7.3-fpm

# Installing php extensions
RUN apt-get update && apt-get install -y \
    wget gnupg2 ca-certificates lsb-release zip unzip git \
    build-essential g++ \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libicu-dev \
    libzip-dev

# Installing nginx
RUN echo "deb http://nginx.org/packages/debian `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list && \
    curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add - && \
    apt-get update && apt-get install nginx && \
    apt-get upgrade -y && \
    apt-get clean

# Removing the rest of apt cache
RUN rm -rf /var/lib/apt/lists

# Enabling php extensions
RUN docker-php-ext-install iconv sockets mbstring mysqli pdo pdo_mysql bcmath zip \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd intl

# Configure PHP
RUN echo "\
max_execution_time = 6000\n\
memory_limit = 256M\n\
upload_max_filesize = 20M\n\
max_file_uploads = 20\n\
default_charset = \"UTF-8\"\n\
short_open_tag = On\n\
cgi.fix_pathinfo = 0\n\
error_reporting = E_ALL & ~E_STRICT & ~E_DEPRECATED" > /usr/local/etc/php/php.ini

RUN echo "\
[global]\n\
daemonize = yes\n\
[www]\n\
listen = 9000" > /usr/local/etc/php-fpm.d/zz-docker.conf

#
# Extended nginx configuration can be placed as *.conf file in
# /etc/nginx/conf.d/
# 
# example:
#
# COPY sample.conf /etc/nginx/conf.d/
#

# Redirecting log outputs to stdout
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443 9000

STOPSIGNAL SIGTERM

CMD ["sh","-c","php-fpm && nginx -g \"daemon off;\""]
