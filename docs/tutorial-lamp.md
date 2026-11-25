# 🚀 Tutorial LAMP paso a paso

## 📁 Los archivos del proyecto (carpeta [`lamp/`](https://github.com/lkyjovska/practica12-lamp-docker/tree/main/lamp))

| Archivo | Qué es |
|---|---|
| [`Dockerfile`](https://github.com/lkyjovska/practica12-lamp-docker/blob/main/lamp/Dockerfile) | La receta de la imagen |
| [`entrypoint.sh`](https://github.com/lkyjovska/practica12-lamp-docker/blob/main/lamp/entrypoint.sh) | El «encargado» que arranca MariaDB en segundo plano y después Apache |
| [`init.sql`](https://github.com/lkyjovska/practica12-lamp-docker/blob/main/lamp/init.sql) | La tabla `comandos` y sus **8 filas** (las *tuplas*) |
| [`index.php`](https://github.com/lkyjovska/practica12-lamp-docker/blob/main/lamp/index.php) | La página: versiones LAMP, todas las filas y el QR |
| [`docker-compose.yml`](https://github.com/lkyjovska/practica12-lamp-docker/blob/main/lamp/docker-compose.yml) | Para desplegarla con un solo comando |
| [`.env.example`](https://github.com/lkyjovska/practica12-lamp-docker/blob/main/lamp/.env.example) | Plantilla de las variables (la contraseña se escribe a mano) |

> 💡 Las filas de la tabla **se ven en la web**, no en GitHub: viven dentro de MariaDB. Aquí solo está el archivo `init.sql`, que es el texto con el que se cargan.

---

## 🚀 Paso a paso

Todo se hace en un servidor con Docker (en mi caso, una VPS Ubuntu llamada *Sauron*).

### 1. Crear la carpeta

```bash
mkdir -p ~/stacks/lenka-lamp && cd ~/stacks/lenka-lamp
```

### 2. Escribir el Dockerfile

Lo escribimos **por bloques** con `cat > Dockerfile <<'EOF'` (la primera vez, con `>`) y `cat >> Dockerfile <<'EOF'` (los siguientes, con `>>`, que **añade al final**).

```dockerfile
# Imagen LAMP: Linux (Debian) + Apache + MariaDB + PHP en una sola imagen
FROM debian:bookworm-slim

LABEL maintainer="Lenka Kyjovska" \
      description="LAMP: Debian + Apache + MariaDB + PHP con pagina de comandos Docker y QR a GitHub"

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Madrid

# Enlace que codificara el QR (se puede cambiar al construir con --build-arg)
ARG GITHUB_URL=https://github.com/lkyjovska

# La L ya es Debian. Se instalan la A, la M y la P, y qrencode para el QR
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
```

**¿Qué hace cada instrucción?**

| Instrucción | En cristiano |
|---|---|
| `FROM debian:bookworm-slim` | Empezamos con un Linux Debian vacío (se baja de Docker Hub solo, no hace falta `docker pull`) |
| `ENV` / `ARG` | Variables: la zona horaria y el enlace del QR |
| `RUN apt-get install ...` | Instalamos Apache, MariaDB, PHP y la herramienta del QR |
| `COPY` | Metemos dentro nuestros archivos |
| `RUN qrencode ...` | **Crea el QR** al construir la imagen, a partir del enlace de GitHub |
| `VOLUME` | La carpeta de datos de la base queda guardada aparte |
| `EXPOSE 80` | Avisa de que la web usa el puerto 80 (solo avisa, no abre nada) |
| `HEALTHCHECK` | Cada 30 s comprueba que la web responde |
| `ENTRYPOINT` | Lo que se ejecuta al arrancar: nuestro script |

### 3. El script de arranque (`entrypoint.sh`)

Es el encargado que abre el local. Estos son los trozos clave (el archivo completo está en [`lamp/entrypoint.sh`](https://github.com/lkyjovska/practica12-lamp-docker/blob/main/lamp/entrypoint.sh)):

```bash
# Si no hay contraseña, el contenedor se niega a arrancar (no hay ninguna escrita en la imagen)
: "${DB_PASS:?Falta la variable DB_PASS}"
export DB_NAME DB_USER DB_PASS

# Solo la primera vez: crear la base, un usuario SOLO LECTURA y cargar los datos
if [ ! -d "/var/lib/mysql/${DB_NAME}" ]; then
  ...
  GRANT SELECT ON ...        # la web solo necesita leer
  mariadb ... < /docker-entrypoint/init.sql
fi

# MariaDB en SEGUNDO PLANO (el & del final) ...
mariadbd --user=mysql &
# ... y después Apache
apache2ctl -D FOREGROUND &

# Si uno de los dos se cae, el contenedor termina y Docker lo reinicia
wait -n
```

### 4. Los datos (`init.sql`) y la página (`index.php`)

`init.sql` crea la tabla `comandos` y mete 8 filas. `index.php` se conecta a MariaDB, hace un `SELECT` y recorre **todas las filas** con un bucle `foreach` para escribirlas en la página, junto con las versiones de Linux, Apache, MariaDB y PHP y el QR.

> 🔐 En el código **no hay ninguna contraseña**: PHP la lee de las variables de entorno (`getenv`).

### 5. Construir la imagen

```bash
docker build -t TU_USUARIO/lenka-lamp:1.0 .
```

(`-t` le pone nombre y versión. Sustituye `TU_USUARIO` por tu usuario de Docker Hub.)

### 6. Probarla antes de publicarla

Primero la contraseña de la base de datos, **escrita a mano** (no se ve mientras la escribes):

```bash
read -rs -p "Contraseña de la BD: " DB_PASS; echo
docker run -d --rm --name lamp-test -e DB_PASS="$DB_PASS" -p 127.0.0.1:8091:80 TU_USUARIO/lenka-lamp:1.0
sleep 15; docker logs lamp-test
curl -s http://127.0.0.1:8091 | sed 's/<[^>]*>/ /g' | grep -v '^\s*$'
```

Deben aparecer las versiones LAMP, las 8 filas y el enlace de GitHub.

### 7. Subirla a Docker Hub

```bash
docker login -u TU_USUARIO
docker stop lamp-test
docker push TU_USUARIO/lenka-lamp:1.0
```

### 8. Desplegarla con Docker Compose

Creamos el `.env` con la contraseña (permisos `600`: solo lo lee tu usuario) y levantamos:

```bash
printf "DB_NAME=lenka_db\nDB_USER=lenka\nDB_PASS='%s'\n" "$DB_PASS" > .env && chmod 600 .env
docker compose up -d
docker ps        # debe poner (healthy)
```

### 9. Publicarla con HTTPS

1. **DNS:** en tu proveedor de dominio, un registro `A` con nombre `lamp` apuntando a la IP del servidor.
2. **Nginx Proxy Manager → Proxy Hosts → Add:** dominio `lamp.tudominio`, esquema `http`, host `lenka-lamp`, puerto `80`.
3. **Pestaña SSL:** *Request a new Certificate* (Let's Encrypt), *Force SSL* y *HTTP/2*.

Y listo: la web se abre con el candado 🔒.

---

## 🛡️ Seguridad aplicada

- La contraseña **no está en la imagen**: se pasa al arrancar con el `.env` (que está en el `.gitignore` y **no se sube a Git**).
- El usuario de la web solo puede **leer** (`GRANT SELECT`).
- MariaDB no se publica fuera del contenedor; la web solo se alcanza a través de NPM con HTTPS.

## 📚 Para saber más

- [Referencia de Dockerfile](https://docs.docker.com/reference/dockerfile/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Imagen oficial de Debian](https://hub.docker.com/_/debian)
- [Nginx Proxy Manager](https://nginxproxymanager.com/)
