#!/usr/bin/env bash

ufw allow 179/tcp
ufw allow 4789/tcp
ufw allow 5473/tcp
ufw allow 443/tcp
ufw allow 6443/tcp
ufw allow 2379/tcp
ufw allow 4149/tcp
ufw allow 10250/tcp
ufw allow 10255/tcp
ufw allow 10256/tcp
ufw allow 9099/tcp
ufw allow 10251/tcp
ufw allow 10252/tcp
ufw allow 8080/tcp
ufw allow 2379:2380/tcp
sudo ufw allow 2380/tcp
sudo ufw reload

{
wget -q --https-only https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssl https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssljson
chmod +x cfssl cfssljson
mv cfssl cfssljson /usr/local/bin/

mkdir -p /opt/certificates && chown vagrant -R $_ && cd $_ 
}

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

join_command=$(kubeadm init --apiserver-advertise-address=${2}.${3} --certificate-key=ca.pem --apiserver-cert-extra-sans=${2}.${3}  --node-name ${4} --pod-network-cidr=${2}.0/16 --ignore-preflight-errors all --token-ttl 0 | grep -A2 'kubeadm join' | xargs -L 2 | paste -sd '')

su ${1} -c 'mkdir -p $HOME/.kube'
su ${1} -c 'sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config'
su ${1} -c 'sudo chown $(id -u):$(id -g) $HOME/.kube/config'
su ${1} -c 'echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> $HOME/.bash_profile'
chown ${1} /etc/kubernetes/admin.conf
echo "export KUBEADM_JOIN=\"${join_command}\"" >> /home/${1}/.bash_profile

su ${1} -c "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"
