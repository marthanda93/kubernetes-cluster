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

# echo "ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y" | su - ${1}
sed -i '/net.ipv4.ip_forward/s/^#//g' /etc/sysctl.conf
sed -i '/net.ipv6.conf.all.forwarding/s/^#//g' /etc/sysctl.conf
sed -i "s/DEFAULT_FORWARD_POLICY=\"DROP\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/g" /etc/default/ufw
sed -i '/net\/ipv4\/ip_forward/s/^#//g' /etc/ufw/sysctl.conf
sed -i '/net\/ipv4\/conf\/all\/forwarding/s/^#//g' /etc/ufw/sysctl.conf
sed -i '/net\/ipv6\/conf\/default\/forwarding/s/^#//g' /etc/ufw/sysctl.conf

ufw enable <<<y
ufw allow 22





instance="192.160.0.10,127.0.0.1,kubernetes.default"
ips=""

for i in $(eval echo {1..$4}); do
	ips="${ip_part}$2.$((10 + $i)),"
done
instance="${ip_part}${instance}"

mkdir -p /opt/kubernetes
cd /opt/kubernetes
{

cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

}

cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:masters",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -hostname=${instance} -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes
sudo chown ${1} -R /opt/kubernetes
