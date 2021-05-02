# vagrant-kubernetes
Kubernetes The Hard Way with Kubeadm on Vagrant

## Big Thanks to kelseyhightower
Most of steps taken from [kelseyhightower public repo](https://github.com/kelseyhightower/kubernetes-the-hard-way).
Arranged accordingly to Vagrant with Virtualbox so that as you run `vagrant up` from `VAAS/kubernetes/hard-way` and wait for completion(it do everythings which is required to setup cluster), after that start using `kubectl` either from your host or any of vm expect `load balancer`.

```bash
$ kubectl get cs
NAME                 STATUS      MESSAGE                        ERROR
scheduler            Healthy     ok
controller-manager   Healthy     ok
etcd-3               Healthy     {"health":"true"}
etcd-0               Healthy     {"health":"true"}
etcd-1               Healthy     {"health":"true"}
```

```bash
$ kubectl get nodes
NAME       STATUS   ROLES    AGE   VERSION
worker-1   Ready    <none>   88s   v1.18.6
worker-2   Ready    <none>   48s   v1.18.6
```

## Prerequisites
This module requires [Vagrant](https://www.vagrantup.com/docs/installation) to pre-installed.
And any virtual environment, defualt can use [oracle virtualbox](https://www.virtualbox.org/wiki/Downloads)

To use kubernetes, can install `kubectl` to access cluster from host but can access via `ssh` to vritual machine also.

## Basic usage
Very first `cd` to path where `Vagrant` file exists(`VAAS/kubernetes/hard-way`), and open `config.yaml` file to update setting before spin up cluster.

### Command line
To start kubernetes cluster please follow below instructions:

```bash
vagrant up
```
