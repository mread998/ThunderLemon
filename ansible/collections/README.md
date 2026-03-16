# Homelab k3s Cluster (HA) – Rebuild Guide

This document describes how to rebuild a **high-availability k3s cluster** in a homelab using:

- 2× control-plane nodes (3 would be better)
- 4× worker nodes
- External control-plane load balancer
- External SQL datastore
- **MetalLB** for bare-metal LoadBalancer services
- **ingress-nginx** as the ingress controller
- **cert-manager** for TLS

This setup is intended to be reproducible, GitOps-friendly, and suitable for running platforms like AWX later.

---

## Architecture Overview

- **Control Plane**: 2 k3s server nodes
- **Workers**: 4 k3s agent nodes
- **API Load Balancer**: NGINX TCP stream LB (port 6443)
- **Datastore**: External MariaDB/MySQL
- **Ingress**: ingress-nginx (Service type LoadBalancer)
- **LoadBalancer IPs**: MetalLB (L2 mode)
- **TLS**: cert-manager + Let’s Encrypt (or internal CA)

---

## Prerequisites

### Networking
- All nodes on the same L2 network
- A reserved IP range for MetalLB (example: `192.168.1.240-192.168.1.250`)
- DNS records pointing to ingress IP(s)

### Systems
- Linux VMs or bare metal (Ubuntu 20.04+ recommended)
- Passwordless SSH access
- Swap disabled on all nodes

```bash
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
```

---

## Step 1 – External Datastore (MariaDB)

Provision a dedicated VM or container for the k3s datastore.

Run basic updates
```sql
apt update && apt upgrade -y
```
Add non-privilaged user (replace username) with sudo permisions
```sql
username=UserName
adduser ${username}
usermod -aG sudo ${username}
```

Install mariadb
```sql
apt install mariadb-server mariadb-client vim net-tools curl
```

Start, enable and check status of mariadb
```sql
systemctl start mariadb
systemctl enable mariadb
systemctl status mariadb
```

Run Secure installation
```sql
sudo mysql_secure_installation
```

Allow remoate login 
```sql
sudo vim /etc/mysql/mariadb.conf.d/50-server.cnf
```

update bind-address from 

```sql
bind-address = 127.0.0.1
```
to 
```sql 
bind-address = 0.0.0.0
```

restart
```sql
reboot
```

Add Mariadb usersS

```sql
CREATE DATABASE k3s;
CREATE USER 'k3s'@'%' IDENTIFIED BY 'STRONG_PASSWORD';
GRANT ALL PRIVILEGES ON k3s.* TO 'k3s'@'%';
FLUSH PRIVILEGES;
```

Connection string format:

```
mysql://k3s:STRONG_PASSWORD@tcp(DB_IP:3306)/k3s
```

---

## Step 2 – Control Plane Load Balancer

Create a small VM/container running **NGINX** in TCP stream mode.

Run basic updates
```sql
apt update && apt upgrade -y
```

Add non-privilaged user (replace username) with sudo permisions
```sql
username=UserName
adduser ${username}
usermod -aG sudo ${username}
```

Install nginx and other tools
```sql
apt install nginx vim net-tools curl
```
update config to turn nginx into load balancer
```sql
vim /etc/nginx/nginx.conf
```
The nginx stream module should be installed

Nginx Config for LB. update ' to k3s k3s server ip
```nginx
load_module /usr/lib/nginx/modules/ngx_stream_module.so;

stream {
    upstream k3s_api {
        server CONTROL_NODE_1_IP:6443;
        server CONTROL_NODE_2_IP:6443;
    }

    server {
        listen 6443;
        proxy_pass k3s_api;
    }
}
```
Check that the config and all modules are installed and will run.
```sql
nginx -t
```

Enable, start and check status
```sql
systemctl start nginx
systemctl enable nginx
systemctl status nginx
```

Check if nginx loadbalancing is working
```sql
nc -vz localhost 6443
```

---

## Step 3 – Install k3s Control Nodes

```sql
apt update && apt upgrade -y
```

Add non-privilaged user (replace username) with sudo permisions
```sql
username=UserName
adduser ${username}
usermod -aG sudo ${username}
```

Install nginx and other tools
```sql
apt install  vim net-tools curl
```

Create database variable replace 'username', 'password' with users created from database setup replace 'database_ip_or_hostname` with database ip and 'port' with port mysql is listing on replace 'database' with the name of database created in database setup

```sql
export K3S_DATASTORE_ENDPOINT='mysql://username:password@tcp(database_ip_or_hostname:port)/database'
```

Create load balancer varible 
```sql
export K3S_LB_IP='YOUR LB IP'
```

Run the K3S instal
```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --datastore-endpoint $K3S_DATASTORE_ENDPOINT \
  --node-taint CriticalAddonsOnly=true:NoExecute \
  --tls-san $K3S_LB_IP \
  --disable traefik \
  --disable servicelb
```

Get node token for other contorl nodes

```sql
sudo cat /var/lib/rancher/k3s/server/node-token
```

### Join Additional Contol Nodes
Create k3s node toke varible.  Copy the out put from 'Get node token' above
```sql
token="SECRET TOKEN"
```

Run though the process up to the k3s install and run the following insted
```sql
curl -sfL https://get.k3s.io | sh -s - server \
  --token=$token \
  --datastore-endpoint $K3S_DATASTORE_ENDPOINT \
  --node-taint CriticalAddonsOnly=true:NoExecute \
  --tls-san $K3S_LB_IP \
  --disable traefik \
  --disable servicelb
```
---

## Step 4 – Join Worker Nodes

Run basic updates
```sql
apt update && apt upgrade -y
```

Add non-privilaged user (replace username) with sudo permisions
```sql
username=UserName
adduser ${username}
usermod -aG sudo ${username}
```

Install other tools
```sql
apt install vim net-tools curl
```

Create k3s node toke varible.  Copy the out put from 'Get node token' from first contoller
```sql
export token="SECRET TOKEN"
```
Create load balancer varible 
```sql
export K3S_LB_IP='YOUR LB IP'
```

Join worker nodes to cluster
```bash
curl -sfL https://get.k3s.io | K3S_URL=https://$K3S_LB_IP:6443 \
  K3S_TOKEN=$token sh -
```

---

## Step 5 – Install MetalLB

Apply the official manifest
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
```

Wait for it to come up
```sql 
kubectl get pods -n metallb-system
```

Create ip pool (adjust ip range as needed)
```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.240-192.168.1.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2
  namespace: metallb-system
```

Apply pool
```sql
kubectl apply -f ip-pool.yaml
```

Test to ensure it's working.  Deploy test stack
```sql
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --type=LoadBalancer --port=80
```

Check that the service is using a pooled IP.  Success means that one of the pooled ip is listed under the external ip list.
```sql
kubectl get svc
```

Clean up test
```sql
kubectl delete deployment nginx
kubectl delete service nginx
```
---

## Step 6 – Install ingress-nginx
Install the official controller manifest
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/baremetal/deploy.yaml
```

Check that it's running
```bash
kubectl get pods -n ingress-nginx
```

patch to make sure it's uisng loadbalancer and not nodeport
```bash
kubectl patch svc ingress-nginx-controller \
  -n ingress-nginx \
  -p '{"spec": {"type": "LoadBalancer"}}'
```

Make ingress-nginx the default ingress class
```sql
kubectl annotate ingressclass nginx ingressclass.kubernetes.io/is-default-class="true"
```

Testing with sample deployment
```bash
kubectl create deployment hello --image=nginxdemos/hello
kubectl expose deployment hello --port=80
```

create ingress
```bash
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello
spec:
  rules:
  - host: hello.lab.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello
            port:
              number: 80
```
Apply ingress for help deployment
```bash
kubectl apply -f hello-ingress.yaml
```

Update local host file to direct to hello.lab.local to the ingress-nginx-contorler extenral ip.  Once done visit hello.lab.local in your browser

Clean up test
```bash
kubectl delete deployment hello
kubectl delete service hello
```
Verify clean up
```bash
kubectl get ingress
kubectl get svc
```

Remove host file entry

---

## Step 7 – Install cert-manager
Install the official manifest
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.yaml
```

Verify it's avalible
```bash
kubectl get pods -n cert-manager
```

Create Clusterissuer Prod (lets encrypt and update email)
```bash
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: you@example.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
```

Create Clusterissuer Stage (lets encrypt and update email)
```bash
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    email: you@example.com
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:
    - http01:
        ingress:
          class: nginx
```
---
## Step 8 – Storage Longhorn
Each server (contol plaine and workers) will get a  dedicated virtual disk, attached directly to the VM, used only by Longhorn.
Giving predictable performance, clean failure domains, and zero weirdness when something goes wrong.

Partition the drives
```bash
gdisk /dev/sdb
```
press n to create a new disk, and follow the prompts
press w to write partiton

Format the disk
```bash
mkfs.xfs /dev/sdb1
```

create the mount point
```bash
mkdir -p /var/lib/longhorn
```

Capture the blkid
```bash
blkid /dev/sdb1
```
copy blkid for fstab

Update fstab
```bash
vim /etc/fstab
``` 

add the following replace xxxx-xxxx with blkid
```bash
UUID=xxxx-xxxx  /var/lib/longhorn  xfs  defaults,noatime  0  0
```

Mount drive
```bash
mount -a
```

Longhorn config
Longhorn runs as root, but Kubernetes still expects sane permissions. Cycle though the servers and verify correct permisions

```bash
sudo chown -R root:root /var/lib/longhorn
sudo chmod 700 /var/lib/longhorn
```

Check if open-iscsi is active
```bash 
systemctl is-active iscsid
```

If inactive run the following:
Install iscsi client
```bash 
sudo apt-get update
sudo apt-get install -y open-iscsi
```

Enable and start service
```bash 
sudo systemctl enable iscsid
sudo systemctl start iscsid
```

Install longhorn
```bash
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.6.2/deploy/longhorn.yaml
```
Adding Longhorn UI Access thoug ingress

Adding http auth 
'''bash
 2003  USER=admin
 2004  PASSWORD='changeme'
 2005  echo "${USER}:$(openssl passwd -stdin -apr1 <<< ${PASSWORD})" > auth
```

Add the http auth file
```bash
 kubectl -n longhorn-system create secret generic longhorn-basic-auth --from-file=auth
 ```

Ceate ingress file as longhorn-ingress.yaml
```bash
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: longhorn-ui
  namespace: longhorn-system
  annotations:
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: longhorn-basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Longhorn Login"
    nginx.ingress.kubernetes.io/proxy-body-size: "10000m"
spec:
  ingressClassName: nginx
  rules:
    - host: longhorn.somedomain.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: longhorn-frontend
                port:
                  number: 80
```
Apply the ingress
```bash
kubectl apply -f longhorn-ingress.yaml
```
Verrify
```bash
kubectl get ingress -n longhorn-system
kubectl get svc -n ingress-nginx
```
After setting proper DNS you will be able to access it from your browser





## Notes

- MetalLB replaces ServiceLB
- ingress-nginx replaces Traefik
- cert-manager should be installed after ingress
- AWX should be deployed via the AWX Operator

## To-do list
- Pin versions or use current for ingress-nginx, cert-manager
- look at updating certmanager to use ingressClassName: nginx insted of ingress: class: nginx.

---
