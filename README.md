# VAAS






Vagrant As Automation Script

DO SMART WORK RATHER THAN HARD WORK!

## Overview

Welcome to the documentation for VAAS - the command line utility for managing the lifecycle of virtual machines.

Automation for create/setup your POC/Working environment also for exam presentation like `CKA`, `CKAD`, `CKS`.

`VAAS` helps you to make you by creating/setup your working Simulator or say POC/Work environment platform which will be ready for your work with minimum efforts.

Every Vagarant file has its own configuration, just update as per your need and say `vagrant up` to start vm and setting up. It may take some time and as its completed you can follow the instructions under how to use section.

## Prerequisites

This module requires [Vagrant](https://www.vagrantup.com/docs/installation) to pre-installed.
And any virtual environment, defualt can use [oracle virtualbox](https://www.virtualbox.org/wiki/Downloads)

## Basic usage

### Command line

To start working `VAAS`, very first clone under your workspace and change your path based on your need.
For Example: Want to setup kubernetes cluster using centos base.

```bash
cd <YOUR WORK SPACE>
git clone git@github.com:marthanda93/VAAS.git

cd kubernetes/centos
vagrant up
```

Once your `vagrant up` is complete, you can use below command line utility.

***To know about you vagarant environments / list down running VMs***
```bash
vagrant status
```

***To SSH to VM***
```bash
vagrant ssh web
```

***To shut down the virtual machine use the command:***
```bash
vagrant halt
```

For specific vm
```bash
vagrant halt worker-node-2
```

***To launch Vagrant using Amazon Web Services with:***

With default vm option
```bash
vagrant up
```

With Vmware Fusion
```bash
vagrant up –provider=vmware_fusion
```

Start specific vm
```bash
vagrant up master-node
```

***To remove all traces of the virtual machine from your system type in the following:***
For all VMs
```bash
vagrant destroy -f
```

For specific VM
```bash
vagrant destroy worker-node-1 -f
```

***To stop the machine and save its current state run:***
```bash
vagrant suspend
```

***To remove image***
```bash
vagrant box remove ubuntu/trusty64
```
