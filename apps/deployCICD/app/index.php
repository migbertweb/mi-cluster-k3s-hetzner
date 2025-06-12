<?php
$redis = new Redis();
$redis->connect('redis-service.redis.svc.cluster.local', 6379);
$redis->auth('gpiro2178');
// CODIGO
$visits = $redis->incr('visits');
echo "<h1>Hola desde PHP en Kubernetes</h1>";
echo "<p>Visitas: $visits</p>";