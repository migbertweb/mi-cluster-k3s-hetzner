<?php
$redis = new Redis();
$redis->connect('redis-service.redis.svc.cluster.local', 6379);
$redis->auth('gpiro2178');
// CODIGO
$visits = $redis->incr('visits');
echo "<h1>Hola desde PHP en Kubernetes</h1>";
echo "<p>Esta es una aplicación PHP desplegada en un clúster de Kubernetes.</p>";
echo "<p>La fecha y hora actual es: " . date('Y-m-d H:i:s') . "</p>";
echo "<p>El nombre del host es: " . gethostname() . "</p>";
echo "<p>El nombre del contenedor es: " . getenv('HOSTNAME') . "</p>";
echo "<p>El nombre del pod es: " . getenv('POD_NAME') . "</p>";

echo "<p>Visitas: $visits</p>";