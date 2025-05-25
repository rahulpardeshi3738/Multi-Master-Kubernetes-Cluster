#!/bin/bash

# Function to read IP and append to /etc/hosts
add_entry() {
    local ip=$1
    local hostname=$2
    echo "$ip ${hostname}.example.com example.com $hostname" >> /etc/hosts
    echo "Added entry: $ip ${hostname}.example.com example.com $hostname"
}

# Run as root check
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Try 'sudo ./add_k8s_hosts.sh'"
   exit 1
fi

# HAProxy
read -p "Enter IP for HAProxy: " haproxy_ip

# Masters
read -p "Enter IP for master1: " master1_ip
read -p "Enter IP for master2: " master2_ip
read -p "Enter IP for master3: " master3_ip

# Nodes
read -p "Enter IP for node1: " node1_ip
read -p "Enter IP for node2: " node2_ip
read -p "Enter IP for node3: " node3_ip

# Append entries to /etc/hosts
add_entry $haproxy_ip haproxy

add_entry $master1_ip master1
add_entry $master2_ip master2
add_entry $master3_ip master3

add_entry $node1_ip node1
add_entry $node2_ip node2
add_entry $node3_ip node3
