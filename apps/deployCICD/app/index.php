<?php
$redis = new Redis();
$redis->connect('redis-service.redis.svc.cluster.local', 6379);

// Leer password del entorno
$redisPassword = getenv('REDIS_PASSWORD');
if ($redisPassword === false) {
    die("No se pudo obtener la contraseña de Redis desde la variable de entorno.");
}

$redis->auth($redisPassword);

// // Verificar si se presionó el botón de reinicio
// if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['reset'])) {
//     $redis->set('visits', 0);
// }

// Incrementar visitas
$visits = $redis->incr('visits');
?>

<!DOCTYPE html>
<html>
<head>
    <title>PHP en Kubernetes</title>
</head>
<body>
    <h1>Hola desde PHP en Kubernetes</h1>
    <p>Esta es una aplicación PHP desplegada en un clúster de Kubernetes.</p>
    <p>La fecha y hora actual es: <?= date('Y-m-d H:i:s') ?></p>
    <p>El nombre del host es: <?= gethostname() ?></p>
    <p>El nombre del contenedor es: <?= getenv('HOSTNAME') ?></p>
    <p><strong>Visitas: <?= $visits ?></strong></p>

    <form method="POST">
        <button type="submit" name="reset">Reiniciar contador</button>
    </form>
</body>
</html>
