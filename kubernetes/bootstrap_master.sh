#!/usr/bin/env bash

sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
yum update -y
yum install -y git wget telnet vim net-tools zip unzip wget curl yum-utils device-mapper-persistent-data lvm2

yum clean all

# Enable transparent masquerading and facilitate Virtual Extensible LAN (VxLAN) traffic for communication between Kubernetes pods across the cluster.
modprobe br_netfilter
firewall-cmd --add-masquerade --permanent
firewall-cmd --reload

# Set bridged packets to traverse iptables rules.
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

# Disable all memory swaps to increase performance.
swapoff -a
