#!/usr/bin/env bash

firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10252/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --reload

join_command=$(kubeadm init --pod-network-cidr=192.168.55.0/24 --apiserver-advertise-address=192.168.55.10 | grep -A2 'kubeadm join' | xargs -L 2 | paste -sd '')
echo $join_command

su vagrant -c 'mkdir -p $HOME/.kube'
su vagrant -c 'sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config'
su vagrant -c 'sudo chown $(id -u):$(id -g) $HOME/.kube/config'
su vagrant -c 'echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> $HOME/.bash_profile'
chown vagrant /etc/kubernetes/admin.conf