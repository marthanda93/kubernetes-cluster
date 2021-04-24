# vagrant-kubernetes
Vagrant for kubernetes

## Prerequisites

This module requires [Vagrant](https://www.vagrantup.com/docs/installation) to pre-installed.
And any virtual environment, defualt can use [oracle virtualbox](https://www.virtualbox.org/wiki/Downloads)

To use kubernetes, can install `kubectl` to access cluster from host but can access via `ssh` to vritual machine also.

## Basic usage
Very first `cd` to path where `Vagrant` file exists, and open `config.yaml` file to update setting before spin up cluster.

### Command line
To start kubernetes cluster please follow below instructions:

```bash
vagrant up
```

**Once `vagrant` complete then can run directly from host**
```bash
$ kubectl get nodes                                                                                                                                                 
NAME            STATUS   ROLES                  AGE   VERSION
master-node     Ready    control-plane,master   34m   v1.21.0
worker-node-1   Ready    worker-node-1          28m   v1.21.0
worker-node-2   Ready    worker-node-2          22m   v1.21.0
```

Also you can access kubernetes cluster from any one virtual machine
```bash
$ vagrant ssh worker-node-1

$ kubectl get nodes                                                                                                                                                 
NAME            STATUS   ROLES                  AGE   VERSION
master-node     Ready    control-plane,master   34m   v1.21.0
worker-node-1   Ready    worker-node-1          28m   v1.21.0
worker-node-2   Ready    worker-node-2          22m   v1.21.0
```

And you are ready to use :smile: