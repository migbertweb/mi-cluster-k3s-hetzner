### Instalar Prometheus y Grafana

**aplicar el secret con el usuario y password para grafana**

```bash
kustomize build --enable-alpha-plugins --enable-exec . | kubectl apply -f -
```

**añadir el repo a Helm**

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

**instalar prometheus y grafana**
```bash
helm install monitoring prometheus-community/kube-prometheus-stack -f values.yaml -n monitoring --create-namespace
```

**verificar los pods**
```bash
kubectl get pods -n monitoring
```