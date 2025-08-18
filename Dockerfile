FROM nextcloud:31-fpm
LABEL org.opencontainers.image.source="https://github.com/davidwroten/nextcloud-fpm-nginx"
LABEL org.opencontainers.image.maintainer="David Wroten <contact@dwroten.com>"


# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ffmpeg \
        imagemagick \
        ghostscript \
        nginx \
        libnginx-mod-http-brotli-filter \
        libnginx-mod-http-brotli-static \
        supervisor \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf
COPY www.conf /usr/local/etc/php-fpm.d/www.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set environment variables for PHP
ENV PHP_MEMORY_LIMIT=2048M \
    PHP_UPLOAD_LIMIT=5G \
    PHP_OPCACHE_MEMORY_CONSUMPTION=1024

# Recommended PHP settings (from official Nextcloud image)
RUN { \
        echo "opcache.enable=1"; \
        echo "opcache.interned_strings_buffer=32"; \
        echo "opcache.max_accelerated_files=100000"; \
        echo "opcache.memory_consumption=${PHP_OPCACHE_MEMORY_CONSUMPTION}"; \
        echo "opcache.save_comments=1"; \
        echo "opcache.revalidate_freq=0"; \
        echo "opcache.jit=1255"; \
        echo "opcache.jit_buffer_size=128M"; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini; \
    echo "apc.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini; \
    { \
        echo "memory_limit=${PHP_MEMORY_LIMIT}"; \
        echo "upload_max_filesize=${PHP_UPLOAD_LIMIT}"; \
        echo "post_max_size=${PHP_UPLOAD_LIMIT}"; \
    } > /usr/local/etc/php/conf.d/nextcloud.ini

# Expose nginx port
EXPOSE 80

# Start supervisord to manage nginx + php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
