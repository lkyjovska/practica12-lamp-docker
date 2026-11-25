<?php
$pdo = new PDO(
  'mysql:unix_socket=/run/mysqld/mysqld.sock;dbname=' . getenv('DB_NAME') . ';charset=utf8mb4',
  getenv('DB_USER'), getenv('DB_PASS'));
$filas = $pdo->query('SELECT id, comando, descripcion FROM comandos')->fetchAll(PDO::FETCH_ASSOC);
$enlace = trim(@file_get_contents('/var/www/html/qr.txt'));
$mariadb = $pdo->query('SELECT VERSION()')->fetchColumn();
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<title>LAMP de Lenka</title>
<style>
  body { font-family: Arial, sans-serif; background: #f5f8fc; color: #1b2b3a; max-width: 820px; margin: 30px auto; padding: 0 16px; }
  h1 { color: #1d6fc4; }
  .caja { background: #fff; border: 1px solid #d6e2f0; border-radius: 10px; padding: 16px; margin-bottom: 18px; }
  table { border-collapse: collapse; width: 100%; }
  th { background: #1d6fc4; color: #fff; text-align: left; padding: 8px; }
  td { padding: 8px; border-bottom: 1px solid #e3ebf5; }
  code { background: #eef3fa; padding: 2px 6px; border-radius: 4px; }
  .qr { text-align: center; }
</style>
</head>
<body>
<h1>LAMP de Lenka</h1>
<div class="caja">
  <b>L</b>inux: <?= php_uname('s') ?> &middot;
  <b>A</b>pache: <?= apache_get_version() ?> &middot;
  <b>M</b>ariaDB: <?= htmlspecialchars($mariadb) ?> &middot;
  <b>P</b>HP: <?= PHP_VERSION ?>
</div>
<div class="caja">
  <h2>Tabla <code>comandos</code> (<?= count($filas) ?> filas)</h2>
  <table>
    <tr><th>id</th><th>comando</th><th>descripcion</th></tr>
<?php foreach ($filas as $f): ?>
    <tr><td><?= $f['id'] ?></td><td><code><?= htmlspecialchars($f['comando']) ?></code></td><td><?= htmlspecialchars($f['descripcion']) ?></td></tr>
<?php endforeach; ?>
  </table>
</div>
<div class="caja qr">
  <h2>Mi GitHub</h2>
  <img src="qr.png" alt="QR a GitHub" width="180"><br>
  <a href="<?= htmlspecialchars($enlace) ?>"><?= htmlspecialchars($enlace) ?></a>
</div>
</body>
</html>
