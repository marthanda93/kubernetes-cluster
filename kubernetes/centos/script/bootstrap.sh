#!/usr/bin/env bash

tee /etc/yum.repos.d/kubernetes.repo<<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
yum update -y
yum install -y epel-release git wget telnet vim net-tools zip unzip wget curl yum-utils device-mapper-persistent-data lvm2 kubelet kubeadm kubectl --disableexcludes=kubernetes

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce iproute-tc

sudo mkdir /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

systemctl enable --now docker
systemctl enable --now kubelet
systemctl enable --now firewalld
usermod -aG docker $1
yum clean all

# Enable transparent masquerading and facilitate Virtual Extensible LAN (VxLAN) traffic for communication between Kubernetes pods across the cluster.
modprobe overlay
modprobe br_netfilter
firewall-cmd --add-masquerade --permanent
firewall-cmd --reload

# Set bridged packets to traverse iptables rules.
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

# Disable all memory swaps to increase performance.
sed -i '/swap/d' /etc/fstab
swapoff -a

# ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y