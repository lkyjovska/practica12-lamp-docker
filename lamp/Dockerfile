# Imagen LAMP de Lenka: Linux (Debian) + Apache + MariaDB + PHP en una sola imagen
FROM debian:bookworm-slim

LABEL maintainer="Lenka Kyjovska" \
      description="LAMP: Debian + Apache + MariaDB + PHP con pagina de comandos Docker y QR a GitHub"

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Madrid

# Enlace que codificara el QR (se puede cambiar al construir con --build-arg)
ARG GITHUB_URL=https://github.com/lkyjovska

# L(inux) ya es Debian. Se instalan la A, la M y la P, y qrencode para el QR
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      apache2 libapache2-mod-php php-mysql mariadb-server qrencode curl ca-certificates tzdata \
 && rm -rf /var/lib/apt/lists/*

# Apache: sin aviso de ServerName, con las variables de la BD visibles para PHP
# y registros por la consola del contenedor (docker logs)
RUN echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf \
 && echo "PassEnv DB_NAME DB_USER DB_PASS" > /etc/apache2/conf-available/dbenv.conf \
 && a2enconf servername dbenv \
 && rm -f /var/www/html/index.html \
 && ln -sf /dev/stdout /var/log/apache2/access.log \
 && ln -sf /dev/stderr /var/log/apache2/error.log

# Pagina PHP, datos iniciales y script de arranque
COPY index.php /var/www/html/index.php
COPY init.sql /docker-entrypoint/init.sql
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# El QR se genera al construir la imagen
RUN chmod +x /usr/local/bin/entrypoint.sh \
 && qrencode -s 8 -m 2 -o /var/www/html/qr.png "${GITHUB_URL}" \
 && echo "${GITHUB_URL}" > /var/www/html/qr.txt

# Los datos de MariaDB viven en un volumen
VOLUME /var/lib/mysql

# Solo documenta: el puerto 80 lo atiende Apache
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD curl -fs http://localhost/ >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
