# Homelab
Home lab notes and docs

# Storage Prep

# Kuberneties setup

## Load Balancer
create an LXC ubuntu 22.04 container

Update your package list and upgrade

``` bash
apt update && apt upgrade -y
```
create username variable and add user with sudo privilges
``` bash
username=UserName
adduser ${username}
usermod -aG sudo ${username}
```

Install nginx and other tools
``` bash
apt install nginx vim net-tools curl
```

update config to turn nginx into load balancer
``` bash
vim /etc/nginx/nginx.conf
```
Nginx Config for LB.  update '<k3s node ip> to k3s k3s server ip
``` bash
events {}

stream {
  upstream k3s_servers {
    server <k3s node ip>:6443;
    server <k3s node ip>:6443;
  }

  server {
    listen 6443;
    proxy_pass k3s_servers;
  }
}
```

Start, enable and check status of nginx
```bash
systemctl start nginx
systemctl enable nginx
systemctl status nginx
```
Check if nginx is listining on port 6443
```bash
netstat -plnt | grep -i 6443
```
Check if network connection is opne on port 6443 for localhost
```bash
nc -vz localhost 6443
```
Check if network connection is opne on port 6443 for load blanacer node ip
nc -vz <load blanacer node ip> 6443
```
## Database
create an LXC ubuntu 22.04 container

update package list and upgrade
``` bash
apt update && apt upgrade -y
```
create username variable and add user with sudo privilges
``` bash
username=UserName
adduser ${username}
usermod -aG sudo ${username}
```
Install MariaDB 10.6 and other tools
``` bash
apt install mariadb-server mariadb-client vim net-tools curl
```
Start, enable and check status of mariadb
```bash
systemctl start mariadb
systemctl enable ngimariadbnx
systemctl status mariadb
```
run Secure install and answer questions
``` bash
sudo mysql_secure_installation
```
Test login
```bash
sudo mariadb -u root -p
```
Allow remote connections
```bash
sudo vim /etc/mysql/mariadb.conf.d/50-server.cnf
```
update bind-address from
```bash 
bind-address = 127.0.0.1
```
To 
```bash 
bind-address = 0.0.0.0
```
restart mariadb
```bash
sudo systemctl restart mariadb
```
log in mariadb as root and create users
``` bash
sudo mariadb -u root -p
```

Create remote user (update 'dbuser' and 'StrongPassword!' if needed)
```bash
CREATE USER 'dbuser'@'%' IDENTIFIED BY 'StrongPassword!';
GRANT ALL PRIVILEGES ON *.* TO 'dbuser'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
```

Create k3s database  (update 'k3sdata' if needed)
``` bash
CREATE DATABASE k3sdata;
```

Create a k3s database new user (update 'k3suser' and 'StrongPassword!' if needed)
```bash
CREATE USER 'k3suser'@'%' IDENTIFIED BY 'StrongPassword!';
```
Grant all privileges on database (update 'k3suser')
``` bash
GRANT ALL PRIVILEGES ON k3sdata.* TO 'k3suser'@'%';
```
Apply Changes
``` bash
FLUSH PRIVILEGES;
```

## Contol Node One

create username variable and add user with sudo privilges
``` bash
username=UserName
adduser ${username}
usermod -aG sudo ${username}
```
Install  and other tools
``` bash
apt install mariadb-server mariadb-client vim net-tools curl
```

## Contol Node One
Create Ubuntu 22.04 VM

update package list and upgrade
``` bash
apt update && apt upgrade -y
```
create username variable and add user with sudo privilges
``` bash
username=UserName
adduser ${username}
usermod -aG sudo ${username}
```
Install other tools
``` bash
apt install  vim net-tools curl
```

Create database variable 
replace 'username', 'password' with users created from database setup
replace 'database_ip_or_hostname` with database ip and 'port' with port mysql is listing on
replace 'database' with the name of database created in database setup
``` bash
export K3S_DATASTORE_ENDPOINT='mysql://username:password@tcp(database_ip_or_hostname:port)/database'
```
Run k3s setup on first contorl node
repacle 'load_balancer_ip_or_hostname' with load balancer ip
``` bash
curl -sfL https://get.k3s.io | sh -s - server --node-taint CriticalAddonsOnly=true:NoExecute --tls-san load_balancer_ip_or_hostname
```
Get node token for other contorl nodes
```bash 
sudo cat /var/lib/rancher/k3s/server/node-token
```

## Adding addiontal Contorl Nodes
Create Ubuntu 22.04 VM

update package list and upgrade
``` bash
apt update && apt upgrade -y
```
create username variable and add user with sudo privilges
``` bash
username=UserName
adduser ${username}
usermod -aG sudo ${username}
```
Install other tools
``` bash
apt install  vim net-tools curl
```
Create database variable (string can be copied from first contol node)
replace 'username', 'password' with users created from database setup
replace 'database_ip_or_hostname` with database ip and 'port' with port mysql is listing on
replace 'database' with the name of database created in database setup
``` bash
export K3S_DATASTORE_ENDPOINT='mysql://username:password@tcp(database_ip_or_hostname:port)/database'
```
Run k3s setup on addional contorl node
replace 'SECRET" with token captured from first contorl node
repacle 'load_balancer_ip_or_hostname' with load balancer ip

``` bash
curl -sfL https://get.k3s.io | sh -s - server --token=SECRET --node-taint CriticalAddonsOnly=true:NoExecute --tls-san load_balancer_ip_or_hostname
```

## Worker Nodes 
Create Ubuntu 22.04 VM

update package list and upgrade
``` bash
apt update && apt upgrade -y
```
create username variable and add user with sudo privilges
``` bash
username=UserName
adduser ${username}
usermod -aG sudo ${username}
```
Install other tools
``` bash
apt install  vim net-tools curl
```
Add worker nodes to k3s
replace <load_balancer_ip_or_hostname> with load balancer ip
replace 'SECRET" with token captured from first contorl node
```bash 
curl -sfL https://get.k3s.io | K3S_URL=https://<load_balancer_ip_or_hostname>:6443 K3S_TOKEN=SECRET sh -
```

Repeat for other contoll nodes

### Final settings

access k3s on contol nodes
``` bash
sudo k3s kubectl get nodes
```

Allow for non-sudo user run command on all nodes
```bash
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```

Allow for remote contol
install kubectl on remote server [kubectl install docs](https://kubernetes.io/docs/tasks/tools/) 

copy the config from one of the contorl nodes
``` bash
sudo cat /etc/rancher/k3s/k3s.yaml
```

past the contents in 
``` bash 
~/.kube/config
```

update server from 127.0.0.1 to ip or host of load balancer

### To Do

Metallb 
cert manager
ingress contoller
media server depolyment



