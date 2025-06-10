<?php
$redis = new Redis();
$redis->connect('redis.default.svc.cluster.local', 6379);

$visits = $redis->incr('visits');
// proba
echo "<h1>Hola desde PHP en Kubernetes</h1>";
echo "<p>Visitas: $visits</p>";
