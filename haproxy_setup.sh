#!/bin/bash

# Install HAproxy
apt update && apt upgrade -y && apt install -y haproxy

# Define the HAProxy config file location
HAPROXY_CONFIG="/etc/haproxy/haproxy.cfg"

#Private IP of HAProxy Server
haproxy_ip=10.18.0.171

# Host name and Private IP of Control Plane Servers
master1=master1
master1_ip=10.18.0.172

master2=master2
master2_ip=10.18.0.173

master3=master3
master3_ip=10.18.0.174

# Configuration snippet to add
CONFIG_HAPROXY=$(cat <<EOF
frontend kubernetes
    bind ${haproxy_ip}:6443
    mode tcp
    option tcplog
    default_backend kubernetes-master-nodes

backend kubernetes-master-nodes
    mode tcp
    option tcp-check
    balance roundrobin
    server ${master1} ${master1_ip}:6443 check fall 3 rise 2
    server ${master2} ${master2_ip}:6443 check fall 3 rise 2
    server ${master3} ${master3_ip}:6443 check fall 3 rise 2
EOF
)

echo "$CONFIG_HAPROXY" | sudo tee -a $HAPROXY_CONFIG > /dev/null

echo "Configuration snippet added to $HAPROXY_CONFIG"

# starting and enabling  HAProxy service

echo "Starting & enabling HAProxy service"

systemctl restart haproxy

systemctl enable haproxy
