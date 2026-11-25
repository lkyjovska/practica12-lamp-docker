# 🐳 Docker cheatsheet

Chuleta de comandos de Docker, con la **explicación sencilla** de cada uno y el **ejemplo que hemos usado en el proyecto**. Cada comando sirve para algo en la pizzería: la *receta* es el Dockerfile, la *pizza congelada* es la imagen y la *pizza servida* es el contenedor.

!!! tip "Cómo leer los nombres"
    `usuario/nombre:etiqueta`, por ejemplo `lkyj004/lenka-lamp:1.0`: **quién** la publica, **qué** es y **qué versión**.

## 🍕 Imágenes (las pizzas congeladas)

| Comando | Qué hace | En nuestro proyecto |
|---|---|---|
| `docker pull imagen` | Descarga una imagen de Docker Hub | `docker pull nginx:alpine` |
| `docker images` | Lista las imágenes que hay en el servidor | `docker images` |
| `docker build -t nombre:version .` | **Construye** una imagen con el Dockerfile de la carpeta actual | `docker build -t lkyj004/lenka-lamp:1.0 .` |
| `docker tag origen destino` | Le pone otro nombre (o versión) a una imagen | `docker tag lenka-lamp lkyj004/lenka-lamp:1.0` |
| `docker history imagen` | Muestra las capas de una imagen | `docker history lkyj004/lenka-lamp:1.0` |
| `docker rmi imagen` | Borra una imagen | `docker rmi nginx:alpine` |

## 🍽️ Contenedores (las pizzas servidas)

| Comando | Qué hace | En nuestro proyecto |
|---|---|---|
| `docker run imagen` | **Crea y arranca** un contenedor | ver más abajo |
| `docker ps` | Lista los contenedores en marcha (`-a`: también los parados) | `docker ps` |
| `docker stop nombre` | Para un contenedor con orden | `docker stop lamp-test` |
| `docker start nombre` | Arranca uno que estaba parado | `docker start lenka-lamp` |
| `docker restart nombre` | Lo reinicia | `docker restart lenka-lamp` |
| `docker rm nombre` | Borra un contenedor parado | `docker rm lamp-test` |
| `docker logs nombre` | Muestra lo que ha escrito (`-f`: en directo, `--tail 20`: las últimas 20) | `docker logs lamp-test` |
| `docker exec -it nombre bash` | Abre una terminal **dentro** del contenedor | `docker exec -it lenka-lamp bash` |
| `docker inspect nombre` | Todos sus datos (red, volúmenes, imagen...) | `docker inspect lenka-lamp` |
| `docker stats` | Uso de CPU y memoria en directo | `docker stats` |
| `docker cp origen destino` | Copia archivos entre el servidor y el contenedor | `docker cp lenka-lamp:/var/www/html/qr.png .` |

### `docker run` y sus opciones más usadas

```bash
docker run -d --rm --name lamp-test -e DB_PASS="$DB_PASS" -p 127.0.0.1:8091:80 lkyj004/lenka-lamp:1.0
```

| Opción | Significa |
|---|---|
| `-d` | En segundo plano (*detached*) |
| `--rm` | Se borra solo al pararlo |
| `--name` | Le da un nombre al contenedor |
| `-e VAR=valor` | Le pasa una variable de entorno (por ejemplo, la contraseña) |
| `-p 127.0.0.1:8091:80` | **Publica** el puerto 80 del contenedor en el 8091 del servidor (solo en local) |
| `-v volumen:/ruta` | Le monta un volumen para guardar datos |
| `--network red` | Lo conecta a una red |

## 🧩 Docker Compose (varias opciones escritas en una hoja)

| Comando | Qué hace |
|---|---|
| `docker compose up -d` | Crea o actualiza los contenedores del `docker-compose.yml` |
| `docker compose down` | Los para y los borra (los volúmenes se conservan) |
| `docker compose ps` | Estado de los servicios |
| `docker compose logs -f` | Registros en directo |
| `docker compose pull` | Descarga las imágenes nuevas |
| `docker compose restart` | Reinicia los servicios |
| `docker compose config` | Comprueba que el archivo está bien escrito |

!!! warning "Ojo"
    Un contenedor en marcha **sigue usando la imagen con la que nació**. Si subes una versión nueva, cambia la etiqueta en el `docker-compose.yml` y ejecuta otra vez `docker compose up -d`: Docker recrea el contenedor.

## ☁️ Docker Hub (la carta de imágenes)

| Comando | Qué hace |
|---|---|
| `docker login -u usuario` | Inicia sesión (la contraseña se escribe a mano) |
| `docker push usuario/nombre:version` | **Sube** tu imagen |
| `docker pull usuario/nombre:version` | La descarga en otro servidor |
| `docker search palabra` | Busca imágenes |
| `docker logout` | Cierra la sesión (conviene al terminar) |

## 🌐 Redes y volúmenes

| Comando | Qué hace |
|---|---|
| `docker network ls` | Lista las redes |
| `docker network create proxy` | Crea una red (los contenedores de una misma red se encuentran por su **nombre**) |
| `docker network inspect proxy` | Quién está conectado a la red |
| `docker volume ls` | Lista los volúmenes (el «congelador» de datos) |
| `docker volume inspect nombre` | Dónde guarda los datos |
| `docker volume rm nombre` | Borra un volumen (**¡se pierden sus datos!**) |

## 📝 Instrucciones del Dockerfile

| Instrucción | Para qué sirve | Ejemplo |
|---|---|---|
| `FROM` | La imagen de la que partimos | `FROM debian:bookworm-slim` |
| `LABEL` | Etiquetas con datos (autor, descripción) | `LABEL maintainer="Lenka"` |
| `ENV` | Variable de entorno fija | `ENV TZ=Europe/Madrid` |
| `ARG` | Variable que solo existe al construir | `ARG GITHUB_URL=https://github.com/lkyjovska` |
| `WORKDIR` | Carpeta de trabajo dentro de la imagen | `WORKDIR /usr/share/nginx/html` |
| `COPY` | Copia archivos del servidor a la imagen | `COPY index.php /var/www/html/` |
| `RUN` | Ejecuta un comando **al construir** (crea una capa) | `RUN apt-get update && apt-get install -y apache2` |
| `EXPOSE` | **Documenta** el puerto (no lo abre) | `EXPOSE 80` |
| `VOLUME` | Marca una carpeta para guardar datos aparte | `VOLUME /var/lib/mysql` |
| `HEALTHCHECK` | Comprueba cada cierto tiempo que todo va bien | `HEALTHCHECK CMD curl -fs http://localhost/` |
| `ENTRYPOINT` | Lo que se ejecuta al **arrancar** el contenedor | `ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]` |
| `CMD` | Orden por defecto (se puede cambiar al hacer `run`) | `CMD ["nginx", "-g", "daemon off;"]` |

!!! info "`EXPOSE` no abre el puerto"
    `EXPOSE` solo **avisa** de qué puerto usa la aplicación. Para abrirlo de verdad hay que **publicarlo** con `-p` (o con `ports:` en Compose). Detrás de Nginx Proxy Manager no hace falta publicar nada: llega por la red.

## 🧹 Limpieza y diagnóstico

| Comando | Qué hace |
|---|---|
| `docker system df` | Cuánto espacio ocupa Docker |
| `docker image prune` | Borra imágenes sin usar |
| `docker system prune` | Limpia contenedores parados, redes y caché sin usar |
| `docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"` | Lista de contenedores con las columnas que tú elijas |
