# INSTALAR METRICS-SERVER

## AÑADIR EL REPO A HELM

```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
```

### Instalar Metrics-server

```bash
helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  -f values.yaml
```
