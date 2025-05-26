<!--toc:start-->

# MI CLUSTER K3S CON TERRAFORM

> y las siguintes herramientas:

* Hetzner Cloud Controller
* Nginx Ingress Controller
* StorageClass NFS-subdir-external-provisioner
* Cert-Manager
* Monitoring con Prometheus y Grafana ... Futuramente Loki*

## PASOS PARA DESPLEGAR CLUSTER EN HETZNER

### En el main.tf file

You can view the latest version of hetznercloud/hcloud in the Terraform Registry.

#### En el .tfvars: Replace <your_api_token> with your actual Hetzner Cloud API token

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

>en la carpeta de Hcloud
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

### Instalar Nginx Ingress Controller

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

Now check if your nodes have the correct provider ID:

```bash
kubectl describe node master-node | grep "ProviderID"
kubectl describe node worker-node-0 | grep "ProviderID"
```

***

#### INSTALAR EL STORAGECLASS NFS-SUBDIR-EXTERNAL-PROVISIONER

**Estara disponible para utilizar en los pvc con el storageclass:nfs-dynamic**

```bash
helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --namespace nfs-provisioner --create-namespace \
    --set nfs.server="10.0.1.1" \
    --set nfs.path="/mnt/nfs_share" \
    --set storageClass.name="nfs-dynamic" \
    --set storageClass.accessModes="ReadWriteMany"
```

***

### OPCIONAL

#### por si algo sale mal

>**Destruye el cluster (Optional)**

```bash
terraform destroy -var-file .tfvars
```

***

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

### DEPLOY DEL SISTEMA MONITORING (PROMETHEUS Y GRAFANA ... FUTURAMENTE LOKI)

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
