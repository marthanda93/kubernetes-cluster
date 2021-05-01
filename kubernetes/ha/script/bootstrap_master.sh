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
    wget -q --https-only "https://github.com/etcd-io/etcd/releases/download/v3.4.10/etcd-v3.4.10-linux-amd64.tar.gz"
    tar -xvf etcd-v3.4.10-linux-amd64.tar.gz
    mv etcd-v3.4.10-linux-amd64/etcd* /usr/local/bin/

    mkdir -p /etc/etcd /var/lib/etcd
    chmod 700 /var/lib/etcd
}

INTERNAL_IP="${1}.$(($2 + $3))"
ETCD_NAME="${4}-${3}"
INSTANCE=""

for i in $(eval echo {1..$5}); do
	INSTANCE="${INSTANCE}$4-$i=https://$1.$(($2 + $i)):2380,"
done

cat <<EOF | tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster ${INSTANCE} \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

{
  systemctl daemon-reload
}
