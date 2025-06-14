<!--toc:start-->

# MI CLUSTER K3S CON TERRAFORM EN HETZNER

> y las siguintes herramientas:

* Hetzner Cloud Controller
* Traefik Ingress Controller
* StorageClass NFS-subdir-external-provisioner
* Metrics Server

## PASOS PARA DESPLEGAR CLUSTER EN HETZNER

> Directorio: infrastructure/terraform-install/

### En el main.tf file

Buscar la ultima version de hetznercloud/hcloud en el Terraform Registry y modificar en el main.tf

#### En el .tfvars: Remplaza <su_api_token_de_hetzner> con la actual Hetzner Cloud API token

hcloud_token = \"your_api_token\"

>Ejecute

```bash
terraform init
```

*revisar la configuracion del master y los cluster en main.tf, revisar la ubicacion y el tipo de plan
y tambien revisar el volumen y su capacidad (10, 20, 30)
Note that running the command below will create new servers in Hetzner Cloud that will be charged.*

>ejecute

```bash
sops --decrypt cloud-init.enc.yaml
sops --decrypt cloud-init-worker.enc.yaml
```

esto creara los yaml con la configuracion de los server.. verifiquelos

```bash
terraform plan -var-file .tfvars
```

>y despues si no muestra ningun error

```bash
terraform apply -var-file .tfvars
```

#### NOTA MUY IMPORTANTE: Copie todos los ID de la salida y guárdelos para más adelante

***

#### Instalar kubectl

```bash
mkdir ~/.kube
scp -i <your_private_ssh_key> cluster@<master_node_public_ip>:/etc/rancher/k3s/k3s.yaml ~/.kube/config
nano ~/.kube/config
```

cambiar la ip con la ip publica del nodo master
>comprobar:

```bash
kubectl get nodes
kubectl get pods -A
```

***

#### instalar Hetzner Cloud Controller

> en la carpeta de Hcloud-secret
> primero edite el network en el archivo cifrado coloque alli el network-id que guardo luego de instalar con terraform

```bash
sops hcloud-secret.enc.yaml
```

> despues aplique el secreto

```bash
kustomize build --enable-alpha-plugins --enable-exec . | kubectl apply -f -
```

> Luego instala el manifiesto de Hetzner Cloud Controller (verificar la version y editar)

```bash
kubectl -n kube-system apply -f https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/download/v1.23.0/ccm-networks.yaml
```

***

### Instalar Traefik Ingres Controller (si desea utilizar Nginx Ingress salte este paso y siga al siguente)

> en la carpeta Traefik-ingress-controller

yo utilizo Cloudflare para la generacion de certificados y necesitas crear y añadir el token
en el secret para que traefik lo utilice para el challenger DNS-01

```bash
kubectl apply -f traefik-secret.yaml
```

>(el secret encryptado es mio :-)
>verifique y edite el values.yaml a sus requerimientos (recuenden que esta adaptado para mi infraestructura)

#### Añadir el repositorio de Helm de Traefik

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
```

#### Instalar Traefik

```bash
helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  -f values.yaml
```

**NOTA IMPORTANTE: Editar el value y modificar el dominio, debe ser un registro DNS válido que apunte a la dirección IP pública de Load Balancers’.**

El controlador debería haber creado un Loadbalancer y
haber conectado todos los nodos (podría tomar un minuto).

![status del loadbalancer](https://blog.kay.sh/content/images/2022/11/Screenshot-2022-11-28-at-12.38.27.png)
>

Ahora verifique si sus nodos tienen el ID de proveedor correcto:

```bash
kubectl describe node master-node | grep "ProviderID"
kubectl describe node worker-node-0 | grep "ProviderID"
```

***

### Instalar Nginx Ingress Controller (Para quien desee utilizar NIC y no traefik)

>en la carpeta: nginx-ingress-controller

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

Instalar Nginx-Ingress-Controller

```bash
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  -f values.yaml
```

**NOTA IMPORTANTE: Editar el value y modificar el dominio, debe ser un registro DNS válido que apunte a la dirección IP pública de Load Balancers’.**

El controlador debería haber creado un Loadbalancer y
haber conectado todos los nodos (podría tomar un minuto).

![status del loadbalancer](https://blog.kay.sh/content/images/2022/11/Screenshot-2022-11-28-at-12.38.27.png)
>

Ahora verifique si sus nodos tienen el ID de proveedor correcto:

```bash
kubectl describe node master-node | grep "ProviderID"
kubectl describe node worker-node-0 | grep "ProviderID"
```

***

#### INSTALAR EL STORAGECLASS NFS-SUBDIR-EXTERNAL-PROVISIONER

**Estara disponible para utilizar en los pvc con el storageclass:nfs-dynamic**
**solo si añadio el storage**

#### En la carpeta infrastructure/storage-nfs-provisoring

```bash
helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --namespace nfs-provisioner \
  --create-namespace \
  --values nfs-provisioner-values.yaml
```

***

### OPCIONAL

#### por si algo sale mal

>**Destruye el cluster (Optional)**

```bash
terraform destroy -var-file .tfvars
```

***

### ESTOS PASOS SON OPCIONALES, INCLUSO SE PUEDEN UTILIZAR CON TRAEFIK O NGINX

### INSTALAR CERT-MANAGER Y VERIFICAR CREANDO CERTIFICADOS STAGING Y DE PRODUCCION

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

### Esperar a que se cree el certificado (suele demorar)

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

***

### DEPLOY DE METRICS-SERVER PARA MONITOREO DEL CLUSTER

>en la carpeta:infrastructure/metrics-server

#### AÑADIR EL REPO A HELM

```bash
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
```

##### Instalar Metrics-server

```bash
helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system \
  -f values.yaml
```

### DEPLOY DEL SISTEMA MONITORING AVANZADO (PROMETHEUS Y GRAFANA ... FUTURAMENTE LOKI)

>en la carpeta monitoring

#### aplicar el secret con el usuario y password para grafana

```bash
kustomize build --enable-alpha-plugins --enable-exec . | kubectl apply -f -
```

#### añadir el repo a Helm

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

>instalar prometheus y grafana

```bash
helm install monitoring prometheus-community/kube-prometheus-stack -f values.yaml -n monitoring --create-namespace
```

>verificar los pods

```bash
kubectl get pods -n monitoring
```
