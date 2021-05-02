#!/usr/bin/env bash

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
add-apt-repository ppa:vbernat/haproxy-1.8 --yes
apt-get update
apt-get install -qq -y haproxy curl wget zip unzip telnet

sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a

tee -a /etc/haproxy/haproxy.cfg << END
        frontend kubernetes
        bind *:6443
        option tcplog
        mode tcp
        default_backend kubernetes-master-nodes
backend kubernetes-master-nodes
        mode tcp
        balance roundrobin
        option tcp-check
$(for i in $(eval echo {1..$4}); do
	echo "        server $3-$i $2.$((10 + $i)):6443 check fall 3 rise 2"
done)
END

modprobe overlay
modprobe br_netfilter

echo "ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y" | su - ${1}
sed -i '/net.ipv4.ip_forward/s/^#//g' /etc/sysctl.conf
sed -i '/net.ipv6.conf.all.forwarding/s/^#//g' /etc/sysctl.conf
sed -i "s/DEFAULT_FORWARD_POLICY=\"DROP\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/g" /etc/default/ufw
sed -i '/net\/ipv4\/ip_forward/s/^#//g' /etc/ufw/sysctl.conf
sed -i '/net\/ipv4\/conf\/all\/forwarding/s/^#//g' /etc/ufw/sysctl.conf
sed -i '/net\/ipv6\/conf\/default\/forwarding/s/^#//g' /etc/ufw/sysctl.conf

ufw enable <<<y
sudo ufw allow 2380/tcp
ufw allow 443/tcp
ufw allow 6443/tcp
ufw allow 22

# The SSH connection was unexpectedly closed by the remote end
echo "ClientAliveInterval 30" >> /etc/ssh/ssh_config
echo "ClientAliveCountMax 5" >> /etc/ssh/ssh_config