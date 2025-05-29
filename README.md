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
