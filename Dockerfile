FROM php:8.3-fpm

WORKDIR /var/www

# -----------------------------
# System dependencies
# -----------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev unzip git curl \
    libonig-dev libicu-dev libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# PHP extensions
# -----------------------------
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j$(nproc) \
    gd pdo pdo_mysql pdo_pgsql mbstring zip intl bcmath pcntl opcache

# -----------------------------
# Redis extension
# -----------------------------
RUN pecl install redis \
 && docker-php-ext-enable redis

# -----------------------------
# Composer
# -----------------------------
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# IMPORTANT: allow plugins (Laravel needs this)
RUN composer config --global allow-plugins true

# -----------------------------
# Install PHP dependencies (cache-friendly)
# -----------------------------
COPY composer.json composer.lock ./

RUN composer install \
    --no-dev \
    --prefer-dist \
    --no-interaction \
    --no-progress \
    --optimize-autoloader

# -----------------------------
# Copy application source
# -----------------------------
COPY . .

# -----------------------------
# Permissions & optimization
# -----------------------------
RUN chown -R www-data:www-data /var/www \
 && find storage -type d -exec chmod 775 {} \; \
 && find storage -type f -exec chmod 664 {} \; \
 && chmod -R 775 bootstrap/cache

# -----------------------------
# Runtime user
# -----------------------------
USER www-data

EXPOSE 9000
CMD ["php-fpm"]
