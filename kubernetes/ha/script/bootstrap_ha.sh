#!/usr/bin/env bash

apt-get update
add-apt-repository ppa:vbernat/haproxy-1.8 --yes
apt-get update
apt-get install -qq -y haproxy curl wget zip unzip telnet

wget -q https://github.com/cloudflare/cfssl/releases/download/v1.5.0/cfssl_1.5.0_linux_amd64 -O /usr/local/bin/cfssl
wget -q https://github.com/cloudflare/cfssl/releases/download/v1.5.0/cfssljson_1.5.0_linux_amd64 -O /usr/local/bin/cfssljson
chmod +x /usr/local/bin/cfssl /usr/local/bin/cfssljson

sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
swapoff -a

tee -a /etc/haproxy/haproxy.cfg << END
        frontend kubernetes
        bind 10.10.10.93:6443
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
systemctl enable --now haproxy

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
ufw allow 22