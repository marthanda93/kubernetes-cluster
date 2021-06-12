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

# disable man-db installation
{
apt-get remove man-db --purge -y
sudo rm -rf /usr/share/locale/
sudo rm -rf /usr/share/man/
sudo rm -rf /usr/share/doc/

cat > /etc/dpkg/dpkg.cfg.d/01_nodoc <<EOF
# Delete locales
path-exclude=/usr/share/locale/*

# Delete man pages
path-exclude=/usr/share/man/*

# Delete docs
path-exclude=/usr/share/doc/*
path-include=/usr/share/doc/*/copyright
EOF
}

apt-get update
apt-get install -y apt-transport-https ca-certificates curl wget zip unzip vim git gnupg lsb-release software-properties-common telnet
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm
apt-mark hold kubelet kubeadm

{
    wget -q --https-only "https://storage.googleapis.com/kubernetes-release/release/v${6}/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/

    mkdir -p /etc/kubernetes/config
    mkdir -p /var/lib/kubernetes/
}

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

# The SSH connection was unexpectedly closed by the remote end
echo -e "ClientAliveInterval 600\nTCPKeepAlive yes\nClientAliveCountMax 10" >> /etc/ssh/sshd_config
