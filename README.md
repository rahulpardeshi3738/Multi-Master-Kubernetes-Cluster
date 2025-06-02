# 🚀 Deploying a Highly Available Kubernetes Cluster with `kubeadm`, HAProxy, and Keepalived on Ubuntu (Bare Metal / VMs)

In this guide, you'll learn how to deploy a **Highly Available Kubernetes Cluster** using:

- `kubeadm` for cluster bootstrapping
- `HAProxy` for load balancing
- `Keepalived` for virtual IP failover

This setup ensures that your Kubernetes **API Server remains accessible**, even if one of your master or load balancer nodes fails.

---

## 🧭 Architecture Overview

### Components:
- **Load Balancers** (2x): HAProxy + Keepalived
- **Masters** (3x): Control Plane Nodes
- **Workers** (3x): Application Nodes
- **Virtual IP (VIP)**: Access point for the Kubernetes API Server

---

## 🛠️ Prerequisites

- **8 Ubuntu 22.04 Servers (VM or Bare Metal)**
- All nodes must be able to communicate over the following ports:
  - `6443` (Kubernetes API Server)
  - `2379-2380` (etcd)
  - `10250-10252`, `10255` (Kubelet and controller ports)
  - `8443` (HAProxy)

### 📦 Node Configuration:

| Role         | Count | Resources                         | Example Instance Type |
|--------------|-------|-----------------------------------|------------------------|
| HAProxy LB   | 2     | 4GB RAM, 2 Core, 20GB Disk         | `t2.medium`            |
| Masters      | 3     | 4GB RAM, 2 Core, 20GB Disk         | `t2.medium`            |
| Workers      | 3     | 1GB RAM, 1 Core, 20GB Disk         | `t2.micro`             |

---

## 🌐 Network & Host Mapping

| Hostname   | IP Address    | FQDN                       |
|------------|---------------|----------------------------|
| VIP        | `10.18.0.170` | (Virtual IP for API Server)|
| haproxy1   | `10.18.0.171` | `haproxy1.kristasoft.com`  |
| haproxy2   | `10.18.0.172` | `haproxy2.kristasoft.com`  |
| master1    | `10.18.0.173` | `master1.kristasoft.com`   |
| master2    | `10.18.0.174` | `master2.kristasoft.com`   |
| master3    | `10.18.0.175` | `master3.kristasoft.com`   |
| worker1    | `10.18.0.176` | `node1.kristasoft.com`     |
| worker2    | `10.18.0.177` | `node2.kristasoft.com`     |
| worker3    | `10.18.0.178` | `node3.kristasoft.com`     |

---

## 📋 Steps Overview

1. ⚙️ **Set up HAProxy + Keepalived for API Server VIP**
2. 🧰 **Prepare Kernel Modules, Networking & Install Containerd**
3. 🔧 **Install Kubernetes Tools (`kubeadm`, `kubelet`, `kubectl`)**
4. 🏗️ **Initialize the Cluster on `master1`**
5. ➕ **Join Additional Masters and Workers**
6. 🌐 **Deploy Weave CNI for Networking**

---

## 📝 Hosts File Configuration

Update the `/etc/hosts` file on **all nodes** to include the following entries:

```plaintext
10.18.0.171 haproxy1.kristasoft.com kristasoft.com haproxy1
10.18.0.172 haproxy2.kristasoft.com kristasoft.com haproxy2
10.18.0.173 master1.kristasoft.com kristasoft.com master1
10.18.0.174 master2.kristasoft.com kristasoft.com master2
10.18.0.175 master3.kristasoft.com kristasoft.com master3
10.18.0.176 node1.kristasoft.com kristasoft.com node1
10.18.0.177 node2.kristasoft.com kristasoft.com node2
10.18.0.178 node3.kristasoft.com kristasoft.com node3
```
---
## ⚙️ Kubernetes Installation with kubeadm and Weave Net (CNI)

These steps must be executed on **all nodes** (masters and workers).

---
### 👤 1. Switch to Root User (All Nodes)
```bash
sudo su -
```
### ❌ 1. Disable Swap (All Nodes)
```bash
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```
### 🧱 2. Load Kernel Modules and Set Sysctl Parameters (All Nodes)
 ```bash
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system
```
### 📦 3. Install and Configure Containerd (All Nodes)
```bash
apt-get update -y 
apt-get install -y ca-certificates curl gnupg lsb-release

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y containerd.io

containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd
```
### 🧰 4. Install Kubernetes Tools: kubeadm and kubectl (All Nodes)
```bash
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gpg

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm
apt-mark hold kubelet kubeadm

systemctl daemon-reload
systemctl start kubelet
systemctl enable kubelet
```
### 🏗️ 5. Initialize Kubernetes Cluster (Master 1 Only)
```bash
kubeadm init --control-plane-endpoint "VIP:6443" --upload-certs
```
### ➕ Join Additional Masters
```bash
kubeadm join VIP:6443 \
  --token <your-token> \
  --discovery-token-ca-cert-hash sha256:<your-ca-hash> \
  --control-plane \
  --certificate-key <your-certificate-key>
```
### ➕ Join Worker Nodes
```bash
kubeadm join VIP:6443 \
  --token <your-token> \
  --discovery-token-ca-cert-hash sha256:<your-ca-hash>```
```
### ⚙️ Set Up kubectl on any server to Access (Master 1 Only)
```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg 
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list  
sudo apt-get update
sudo apt-get install -y kubectl
```
### ➕ Get config file from Master 1
```bash
cat /etc/kubernetes/admin.conf  
```
### ➕ Update config file from Master 1 to server where kubeclt is installed
```bash
vim $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

### 🌐 6. Install Weave Net (CNI Plugin)
```bash
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
```
