FROM php:8.3-cli

RUN docker-php-ext-install sockets

# Instalar Redis extension
RUN pecl install redis && docker-php-ext-enable redis

WORKDIR /app
COPY app/ /app

CMD ["php", "-S", "0.0.0.0:80", "index.php"]
