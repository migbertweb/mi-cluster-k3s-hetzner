<?php
$redis = new Redis();
$redis->connect('redis-service.redis.svc.cluster.local', 6379);

$visits = $redis->incr('visits');
// mejore el workflow2
echo "<h1>Hola desde PHP en Kubernetes</h1>";
echo "<p>Visitas: $visits</p>";
