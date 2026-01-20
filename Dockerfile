FROM php:8.3-fpm

WORKDIR /var/www

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev unzip git curl \
    libonig-dev libicu-dev libpq-dev \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j$(nproc) \
    gd pdo pdo_mysql pdo_pgsql mbstring zip intl bcmath pcntl opcache

RUN pecl install redis && docker-php-ext-enable redis

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --no-autoloader

COPY . .

RUN composer dump-autoload --optimize --classmap-authoritative \
 && chown -R www-data:www-data /var/www \
 && find storage -type d -exec chmod 775 {} \; \
 && find storage -type f -exec chmod 664 {} \; \
 && chmod -R 775 bootstrap/cache

USER www-data

EXPOSE 9000
CMD ["php-fpm"]
