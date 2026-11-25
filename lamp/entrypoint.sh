#!/bin/bash
# Arranque del contenedor: prepara MariaDB (solo la primera vez), la deja
# funcionando en segundo plano y despues arranca Apache.
set -e

DB_NAME="${DB_NAME:-lenka_db}"
DB_USER="${DB_USER:-lenka}"
: "${DB_PASS:?Falta la variable DB_PASS (contrasena del usuario de la base de datos)}"

export DB_NAME DB_USER DB_PASS
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

esperar_mariadb() {
  for i in $(seq 1 30); do
    mariadb-admin ping --silent 2>/dev/null && return 0
    sleep 1
  done
  echo "MariaDB no arranco a tiempo" >&2
  return 1
}

# 1) Primera vez: crear el directorio de datos, la base, el usuario y los datos
if [ ! -d "/var/lib/mysql/${DB_NAME}" ]; then
  echo ">> Primera ejecucion: inicializando MariaDB"
  [ -d /var/lib/mysql/mysql ] || mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
  mariadbd --user=mysql --skip-networking &
  TEMP_PID=$!
  esperar_mariadb
  mariadb <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT SELECT ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL
  mariadb --default-character-set=utf8mb4 "${DB_NAME}" < /docker-entrypoint/init.sql
  mariadb-admin shutdown
  wait "$TEMP_PID" || true
  echo ">> Base de datos ${DB_NAME} creada"
fi

# 2) MariaDB en segundo plano (solo escucha dentro del contenedor)
mariadbd --user=mysql &
MARIADB_PID=$!
esperar_mariadb

# 3) Apache en primer plano
apache2ctl -D FOREGROUND &
APACHE_PID=$!

parar() {
  echo ">> Parando servicios"
  apache2ctl -k stop 2>/dev/null || true
  mariadb-admin shutdown 2>/dev/null || true
  wait
  exit 0
}
trap parar TERM INT

# Si uno de los dos se cae, el contenedor termina y Docker lo reinicia
wait -n "$MARIADB_PID" "$APACHE_PID"
echo ">> Un servicio se ha parado" >&2
parar
