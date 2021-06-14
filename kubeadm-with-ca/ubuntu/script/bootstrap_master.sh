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

# Certificate Authority
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