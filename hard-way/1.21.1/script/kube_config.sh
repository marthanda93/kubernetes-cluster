#!/usr/bin/env bash

cd /opt/certificates
lb_ip="$1.$4"

# The kubelet Kubernetes Configuration File
for i in $(eval echo {1..$8}); do
    instance="$6-$i"
    
    kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=ca.pem --embed-certs=true --server=https://${lb_ip}:6443 --kubeconfig=${instance}.kubeconfig
    kubectl config set-credentials system:node:${instance} --client-certificate=${instance}.pem --client-key=${instance}-key.pem --embed-certs=true --kubeconfig=${instance}.kubeconfig
    kubectl config set-context default --cluster=kubernetes-the-hard-way --user=system:node:${instance} --kubeconfig=${instance}.kubeconfig
    kubectl config use-context default --kubeconfig=${instance}.kubeconfig
done

# The kube-proxy Kubernetes Configuration File
{
    kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=ca.pem --embed-certs=true --server=https://${lb_ip}:6443 --kubeconfig=kube-proxy.kubeconfig
    kubectl config set-credentials system:kube-proxy --client-certificate=kube-proxy.pem --client-key=kube-proxy-key.pem --embed-certs=true --kubeconfig=kube-proxy.kubeconfig
    kubectl config set-context default --cluster=kubernetes-the-hard-way --user=system:kube-proxy --kubeconfig=kube-proxy.kubeconfig
    kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
}

# The kube-controller-manager Kubernetes Configuration File
{
    kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=ca.pem --embed-certs=true --server=https://${lb_ip}:6443 --kubeconfig=kube-controller-manager.kubeconfig
    kubectl config set-credentials system:kube-controller-manager --client-certificate=kube-controller-manager.pem --client-key=kube-controller-manager-key.pem --embed-certs=true --kubeconfig=kube-controller-manager.kubeconfig
    kubectl config set-context default --cluster=kubernetes-the-hard-way --user=system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig
    kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
}

# The kube-scheduler Kubernetes Configuration File
{
    kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=ca.pem --embed-certs=true --server=https://${lb_ip}:6443 --kubeconfig=kube-scheduler.kubeconfig
    kubectl config set-credentials system:kube-scheduler --client-certificate=kube-scheduler.pem --client-key=kube-scheduler-key.pem --embed-certs=true --kubeconfig=kube-scheduler.kubeconfig
    kubectl config set-context default --cluster=kubernetes-the-hard-way --user=system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig
    kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
}

# The admin Kubernetes Configuration File
{
    kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=ca.pem --embed-certs=true --server=https://${lb_ip}:6443 --kubeconfig=admin.kubeconfig
    kubectl config set-credentials admin --client-certificate=admin.pem --client-key=admin-key.pem --embed-certs=true --kubeconfig=admin.kubeconfig
    kubectl config set-context default --cluster=kubernetes-the-hard-way --user=admin --kubeconfig=admin.kubeconfig
    kubectl config use-context default --kubeconfig=admin.kubeconfig
}

# The Encryption Config File
{
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF
}

chown vagrant -R /opt/certificates
