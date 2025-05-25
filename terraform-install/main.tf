# Tell Terraform to include the hcloud provider
terraform {
  required_version = ">= 1.11.1"
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      # Here we use version 1.50.0, this may change in the future
      version = "1.50.0"
    }
  }
}
# Declare the hcloud_token variable from .tfvars
variable "hcloud_token" {
  type      = string
  sensitive = true # Requires terraform >= 0.14
}
# Configure the Hetzner Cloud Provider with your token
provider "hcloud" {
  token = var.hcloud_token
}
##############################################################
########## Crear un VOLUMEN en Hetzner (será usado por el NFS)
resource "hcloud_volume" "nfs_volume" {
  name     = "nfs-storage"
  size     = 30     # Tamaño en GB
  format   = "ext4" # Formato del sistema de archivos
  location = "nbg1" # Debe coincidir con la ubicación de tus nodos
}
########################################
########## CREAR LA RED PRIVADA ########
resource "hcloud_network" "private_network" {
  name     = "kubernetes-cluster"
  ip_range = "10.0.0.0/16"
}
resource "hcloud_network_subnet" "private_network_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.private_network.id
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}
########################################
###########  CREAR EL FIREWALL #########
resource "hcloud_firewall" "k3s_firewall" {
  name = "k3s-firewall"

  # Reglas básicas de acceso
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "SSH"
  }

  rule {
    direction   = "in"
    protocol    = "icmp"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "ICMP/Ping"
  }

  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "53"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "DNS"
  }
  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "123"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "NTP"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "53"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "DNS-TCP"
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Web (HTTP)"
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Web (HTTPS)"
  }
  # Kubernetes (K3S)
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "K3S API"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "10250"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Kubelet"
  }
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "2379-2380"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "etcd"
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "8472"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Flannel TCP"
  }

  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "8472"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Flannel UDP"
  }

  # Almacenamiento y VPN
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "2049"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "NFS TCP"
  }

  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "2049"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "NFS UDP/WireGuard"
  }

  rule {
    direction   = "in"
    protocol    = "udp"
    port        = "51820"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "NFS UDP/WireGuard"
  }
  # Monitorización
  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "3000"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Grafana"
  }
rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "9090"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Prometheus"
  }
rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "9100"
    source_ips  = ["0.0.0.0/0", "::/0"]
    description = "Node-Exporter"
  }

  # Reglas de salida
  rule {
    direction         = "out"
    protocol         = "icmp"
    destination_ips  = ["0.0.0.0/0", "::/0"]
    description      = "Out ICMP"
  }

  rule {
    direction         = "out"
    protocol         = "tcp"
    port             = "1-65535"
    destination_ips  = ["0.0.0.0/0", "::/0"]
    description      = "All TCP Out"
  }

  rule {
    direction         = "out"
    protocol         = "udp"
    port             = "1-65535"
    destination_ips  = ["0.0.0.0/0", "::/0"]
    description      = "All UDP Out"
  }
}

########################################
########## CREAR EL NODO MASTER ########
resource "hcloud_server" "master-node" {
  name         = "master-node"
  image        = "ubuntu-24.04"
  server_type  = "cax11"
  location     = "nbg1"

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network.private_network.id
    # IP Used by the master node, needs to be static
    # Here the worker nodes will use 10.0.1.1 to communicate with the master node
    ip = "10.0.1.1"
  }

  # Adjuntar el firewall al servidor
  firewall_ids = [hcloud_firewall.k3s_firewall.id]

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    VOLUME_ID    = hcloud_volume.nfs_volume.id
    SUBNET_RANGE = hcloud_network_subnet.private_network_subnet.ip_range
  })

  # user_data = file("${path.module}/cloud-init.yaml")
  depends_on = [
    hcloud_network_subnet.private_network_subnet,
    hcloud_volume.nfs_volume, # Todas las dependencias en una lista
  ]
  #fin crear nodo master
}

##### Conectar el volumen al nodo master
resource "hcloud_volume_attachment" "nfs_volume_attachment" {
  volume_id = hcloud_volume.nfs_volume.id
  server_id = hcloud_server.master-node.id
  automount = true # Hetzner intentará montarlo automáticamente
}

########################################
########## CREAR EL NODO WORKER ########
resource "hcloud_server" "worker-nodes" {
  count = 1
  # The name will be worker-node-0, worker-node-1, worker-node-2...
  name         = "worker-node-${count.index}"
  image        = "ubuntu-24.04"
  server_type  = "cax11"
  location     = "nbg1"

  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network.private_network.id
  }

  # Aquí asocias el firewall a cada nodo worker
  firewall_ids = [hcloud_firewall.k3s_firewall.id]

  #user_data = file("${path.module}/cloud-init-worker.yaml")
  user_data = templatefile("${path.module}/cloud-init-worker.yaml", {
    NFS_SERVER_IP = one(hcloud_server.master-node.network).ip
  })
}

################################################
# Outputs al final del archivo (nivel raíz)
# id de la red privada
output "network_id" {
  value = hcloud_network.private_network.id
}
# id del volumen
output "volume_id" {
  value = hcloud_volume.nfs_volume.id
}
# ip del nodo master
output "master_private_ip" {
  value = one(hcloud_server.master-node.network).ip
}
# ip de los nodos workers
output "worker_ips" {
  value = [for server in hcloud_server.worker-nodes : one(server.network).ip]
}
######## FIN  ###############
