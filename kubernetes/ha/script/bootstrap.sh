#!/usr/bin/env bash

cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

# Disable all memory swaps to increase performance.
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a

apt-get update
apt-get install -y apt-transport-https ca-certificates curl wget zip unzip vim git gnupg lsb-release software-properties-common telnet
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
# add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
# apt-get update
# apt-get install -y docker-ce docker-ce-cli containerd.io
# usermod -aG docker ${1}

# cat <<EOF | tee /etc/docker/daemon.json
# {
#   "exec-opts": ["native.cgroupdriver=systemd"],
#   "log-driver": "json-file",
#   "log-opts": {
#     "max-size": "100m"
#   },
#   "storage-driver": "overlay2"
# }
# EOF

# systemctl enable --now docker

# Enable transparent masquerading and facilitate Virtual Extensible LAN (VxLAN) traffic for communication between Kubernetes pods across the cluster.
modprobe overlay
modprobe br_netfilter

echo "ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y" | su - ${1}
sed -i '/net.ipv4.ip_forward/s/^#//g' /etc/sysctl.conf
sed -i '/net.ipv6.conf.all.forwarding/s/^#//g' /etc/sysctl.conf
sed -i "s/DEFAULT_FORWARD_POLICY=\"DROP\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/g" /etc/default/ufw
sed -i '/net\/ipv4\/ip_forward/s/^#//g' /etc/ufw/sysctl.conf
sed -i '/net\/ipv4\/conf\/all\/forwarding/s/^#//g' /etc/ufw/sysctl.conf
sed -i '/net\/ipv6\/conf\/default\/forwarding/s/^#//g' /etc/ufw/sysctl.conf
mkdir -p /home/vagrant/certificates && chown vagrant:vagrant -R $_

ufw enable <<<y
ufw allow 22
