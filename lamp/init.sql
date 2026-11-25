CREATE TABLE comandos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  comando VARCHAR(60) NOT NULL,
  descripcion VARCHAR(120) NOT NULL
);

INSERT INTO comandos (comando, descripcion) VALUES
('docker pull', 'Descarga una imagen de Docker Hub'),
('docker build', 'Construye una imagen desde un Dockerfile'),
('docker push', 'Sube una imagen a Docker Hub'),
('docker run', 'Crea y arranca un contenedor'),
('docker ps', 'Lista los contenedores en marcha'),
('docker logs', 'Muestra los registros de un contenedor'),
('docker exec', 'Ejecuta un comando dentro de un contenedor'),
('docker compose up -d', 'Levanta los servicios del compose');
