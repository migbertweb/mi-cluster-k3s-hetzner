## CONFIGURACION DE MARIADB
### INSTALAR TODO CON KUSTOMIZE
**el secret se genera con ksops**

```bash
kustomize build kustomize-mariadb/overlays/prod | kubectl apply -f -
```

 🌐 Agrega ese puerto (32306) al Load Balancer en Hetzner Cloud
Ve a la consola de Hetzner:
Entra al Load Balancer.
Pestaña "Targets" → asegúrate que todos los nodos están como targets.
Pestaña "Services" → agrega un nuevo servicio:

```yaml
Protocol: TCP
Public Port: 3306
Target Port: 32306
```

**para crear el usuario y la base de datos ejecuta:**

```bash
kubectl delete pvc -n mysql-ns -l app=mariadb
kubectl delete pod -n mysql-ns -l app=mariadb
```bash