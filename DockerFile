# ---- base PHP-FPM image ----
FROM php:8.4-fpm

# Workdir
WORKDIR /var/www

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libzip-dev unzip git curl \
    libonig-dev libicu-dev libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j$(nproc) gd pdo pdo_mysql pdo_pgsql mbstring zip intl bcmath pcntl

# Opcache (performance)
RUN docker-php-ext-install opcache

# Redis extension (queue/cache)
RUN pecl install redis \
 && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# -------------------------------
# Step 1: Install dependencies (cache friendly)
# -------------------------------
COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --no-autoloader

# -------------------------------
# Step 2: Copy application code
# -------------------------------
COPY . .

# Ensure writable dirs
RUN chown -R www-data:www-data storage bootstrap/cache \
 && find storage -type d -exec chmod 775 {} \; \
 && find storage -type f -exec chmod 664 {} \; \
 && chmod -R 775 bootstrap/cache

# -------------------------------
# Step 3: Dump optimized autoloader (after code exists)
# -------------------------------
RUN composer dump-autoload --optimize --classmap-authoritative

# (Optional) pre-cache config/routes if APP_KEY present at build time
# RUN php artisan config:cache && php artisan route:cache || true

# Switch user
USER www-data

EXPOSE 9000
CMD ["php-fpm"]
