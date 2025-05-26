# INSTALAR CERT-MANAGER Y VERIFICAR CREANDO CERTIFICADOS STAGING Y DE PRODUCCION

En la carpeta cert-manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --values=values.yaml --version v1.17.1
```

> en la carpeta kustomize

```bash
kustomize build --enable-alpha-plugins --enable-exec overlay/prod | kubectl apply -f -
```

>Luego si desea puede crear certificados y verificar que todo funcione
en la carpeta certificates

```bash
kubectl apply -f staging-cert.yaml
kubectl apply -f production-cert.yaml
```

> verificar todo

```bash
kubectl get ClusterIssuer -A
kubectl describe clusterissuer staging-cert
kubectl describe clusterissuer production-cert
kubectl get cert -n default
```

> Verificar la creacion del certificado:

```bash
kubectl get challenges
kubectl get orders -w
kubectl describe order .....
```

## Esperar a que se cree el certificado (suele demorar)

***

### DEPLOY DE PRUEBA

> en la carpeta deploy-prueba

```bash
cd deploy-prueba
kubectl apply -f certificates-test.yaml
```

>esto va a crear un namespace de prueba y certificados para ese namespace (luego se pueden borrar mas facilmente)

```bash
kubectl apply -f test-httpd-deploy.yaml
```

*esto va a crear un deployment de httpd, su service y su ingress*
*despues verificar en el host:local.migbertweb.xyz,
 pruebe los dos certificados, siempre primero el staging*
