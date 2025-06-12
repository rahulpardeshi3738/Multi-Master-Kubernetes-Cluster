# ⚙️ High Availability Kubernetes API VIP with HAProxy + Keepalived

This guide sets up a Virtual IP (VIP) using HAProxy and Keepalived for Kubernetes API server access. This ensures high availability and load balancing across master nodes.

---

## 🖥️ 1. Host Configuration

 #### Set Hostnames (run on each HAProxy server):
```bash
sudo hostnamectl set-hostname <hostname>  # Replace with e.g., haproxy1 or haproxy2
```

#### Add All Nodes to /etc/hosts
```
cat << EOF | sudo tee -a /etc/hosts
10.18.0.171 haproxy1.kristasoft.com haproxy1
10.18.0.172 haproxy2.kristasoft.com haproxy2
10.18.0.173 master1.kristasoft.com master1
10.18.0.174 master2.kristasoft.com master2
10.18.0.175 master3.kristasoft.com master3
10.18.0.176 node1.kristasoft.com node1
10.18.0.177 node2.kristasoft.com node2
10.18.0.178 node3.kristasoft.com node3
EOF
```

### 📦 2. Install HAProxy and Keepalived
```
sudo apt update && sudo apt upgrade -y
sudo apt install -y haproxy keepalived
sudo systemctl enable haproxy
sudo systemctl enable keepalived
```

### ⚙️ 3. Configure HAProxy
```
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak
```
```
cat << EOF | sudo tee -a /etc/haproxy/haproxy.cfg
# Kubernetes API Server
frontend kubernetes-api
    bind *:6443
    mode tcp
    option tcplog
    default_backend kubernetes-api-backend

backend kubernetes-api-backend
    mode tcp
    option tcplog
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
    server master1 10.18.0.173:6443 check fall 3 rise 2
    server master2 10.18.0.174:6443 check fall 3 rise 2
    server master3 10.18.0.175:6443 check fall 3 rise 2
EOF
```
```
sudo systemctl restart haproxy
```

### 🛡️ 4. Configure Keepalived
#### - On haproxy1 (10.18.0.171) - MASTER:
```
cat << EOF | sudo tee /etc/keepalived/keepalived.conf
vrrp_instance haproxy-vip {
    state MASTER
    interface ens18  # Replace with your interface, check via: ip addr show
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass krista123
    }
    virtual_ipaddress {
        10.18.0.180/24
    }
}
EOF

```
```
sudo systemctl restart keepalived
```

#### - On haproxy2 (10.18.0.172) - BACKUP:
```
cat << EOF | sudo tee /etc/keepalived/keepalived.conf
vrrp_instance haproxy-vip {
    state BACKUP
    interface ens18  # Replace with your interface, check via: ip addr show
    virtual_router_id 51
    priority 90
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass krista123
    }
    virtual_ipaddress {
        10.18.0.180/24
    }
}
EOF
```
```
sudo systemctl restart keepalived
```
### ✅ Verification Steps
- Ensure VIP 10.18.0.180 is active on MASTER node (ip addr show | grep 10.18.0.180 )

### 🔐 Notes
- Replace ens18 with your actual network interface.
- Ensure firewall allows port 6443 and VRRP traffic (protocol 112).
- We can also configure HAProxy and  Keepalived in Master nodes itself.



