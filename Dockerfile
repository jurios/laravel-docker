FROM php:7.2-fpm

ENV COMPOSER_URL https://getcomposer.org/installer
ENV COMPOSER_SHA 544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061

RUN php -r "copy('$COMPOSER_URL', 'composer-setup.php');"
RUN php -r "if (hash_file('SHA384', 'composer-setup.php') === '$COMPOSER_SHA') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN php -r "unlink('composer-setup.php');"

RUN apt-get update \
    && apt-get install -q -y --no-install-recommends \
    curl \
    libmemcached-dev \
    libz-dev \
    libpq-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libssl-dev \
    libmcrypt-dev \
    unzip \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install pdo_mysql \
    && docker-php-ext-configure gd \
    --enable-gd-native-ttf \
    --with-jpeg-dir=/usr/lib/ \
    --with-freetype-dir=/usr/include/freetype2 \
    && docker-php-ext-install -j$(nproc) gd



RUN chown -R www-data:www-data /var/www

RUN mkdir -p /app
WORKDIR /app

COPY . .
RUN chown -R www-data:www-data /app

USER www-data

RUN composer install \
    && cat .env.example | sed -e "s/DB_HOST=127.0.0.1/DB_HOST=db/" | sed -e "s/APP_DEBUG=true/APP_DEBUG=false/" > .env \
    && php artisan key:generate \
    && cat .env

RUN ls -la /app
WORKDIR /var/www/html

CMD rm -fr /var/www/html/* \
    && cp -r /app/* /var/www/html \
    && cp /app/.env /var/www/html \
    && sleep 10 \
    && php artisan storage:link \
    && php artisan migrate --seed \
    && php-fpm
