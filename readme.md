# Nextcloud FPM + Nginx (Supervisor Managed)

This repository provides a Docker image for running Nextcloud with:

* **PHP-FPM** (for better performance vs Apache prefork model)
* **Nginx** as the webserver
* **Supervisor** to manage both processes inside a single container
* **Brotli & gzip compression** for optimized responses
* **Tuned PHP-FPM and Nginx configs** for high-performance environments (8 CPU cores / 32 GB RAM)

It is based on the official `nextcloud:fpm` image but enhanced for simplicity and speed.

## Why this image?

The official Nextcloud Docker images come in two flavors:

* nextcloud:apache (Apache + prefork PHP) – easy but not the most efficient
* nextcloud:fpm (just PHP-FPM) – faster, but you must provide your own webserver

Instead of maintaining two containers (one for FPM and one for Nginx), this image runs **both Nginx and PHP-FPM inside a single container**, supervised by supervisord.

This approach provides:

* Simpler deployment (no extra container wiring required)
* Better performance from PHP-FPM + tuned Nginx
* Brotli + gzip compression out of the box
* Configurations optimized for large instances

## Features

✅ Based on `nextcloud:31-fpm`  
✅ Nginx with Brotli & gzip enabled  
✅ Supervisor to run `php-fpm` and `nginx` together  
✅ Optimized `nginx.conf` for Nextcloud (security headers, caching, `.well-known` handling, etc.)  
✅ Optimized PHP-FPM pool settings (`www.conf`) for multi-core environments  
✅ Tuned Opcache / APCu / memory / upload limits  

## Usage

Build the image:
```bash
docker build -t nextcloud-fpm-nginx .
```
Run the container (basic example):
```bash
docker run -d \
  -p 8080:80 \
  -v nextcloud_data:/var/www/html \
  --name nextcloud-app \
  nextcloud-fpm-nginx
```
Then visit:👉 http://localhost:8080

## Configuration Details

PHP-FPM tuning

Runs under `www-data`

* Configured for **dynamic process management** with higher concurrency:
```ini
pm.max_children = 150
pm.start_servers = 20
pm.min_spare_servers = 15
pm.max_spare_servers = 40
```
* Memory limit: `2048M`
* Upload limit: `5G`
* Opcache tuned (`1024MB`, `jit`, etc.)

### Nginx

* 8 worker processes (adjustable)
* File Descriptor limit `worker_rlimit_nofile 65535;`
* Worker connections `worker_connections 2048;`
* Brotli & gzip compression enabled for modern performance
* Secure headers (`X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, etc.)
* Optimized caching rules for assets and fonts
* Nextcloud-specific routing (`/.well-known`, DAV clients, etc.)

### Supervisor

Manages both services:

* `php-fpm` via Nextcloud’s entrypoint script
* `nginx` in foreground mode

This ensures container lifecycle is properly tied to both processes.

## Volumes

You’ll likely want to mount:

/var/www/html → Nextcloud app + data

Example:
```bash
docker run -d \
  -p 8080:80 \
  -v /srv/nextcloud/html:/var/www/html \
  nextcloud-fpm-nginx
```

## Notes

* TLS/SSL is not configured in this container. You should put it behind a reverse proxy (e.g. Traefik, Caddy, or Nginx with Let’s Encrypt).
* `supervisord` keeps both processes alive; if either crashes, it will restart automatically.
* This container is tuned for **8 cores / 32 GB RAM** but configs can be adjusted for smaller environments.

## Roadmap / Future Ideas

* Add optional HTTP/2 & QUIC support
* Multi-arch builds (arm64, amd64)
* Further tuning for small deployments (alternative configs)