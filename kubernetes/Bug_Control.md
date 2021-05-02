# Error Control Vagrant Kubernetes
While using `vagrant / vagrantfile` you can encounter of some errors, try to add few errors which faced during development of `kubernetes vagrant` file with solutions which worked whenever faced issues.

### SSH connection get timeout or say ssh connection got reset, something like below error

```bash
SSH connection was reset! This usually happens when the machine is
taking too long to reboot. First, try reloading your machine with
`vagrant reload`, since a simple restart sometimes fixes things.
If that doesn't work, destroy your machine and recreate it with
a `vagrant destroy` followed by a `vagrant up`. If that doesn't work,
contact support.
```

> Then can try to add below config to your vagrantfile
```bash
    config.vm.boot_timeout = 600
```

> if still not solved then best can try
```bash
$ rm -rf .vagrant
```

### While creating VM, vagrant failed to rename vm because of unclear vms
```bash
The name of your virtual machine couldn't be set because VirtualBox
is reporting another VM with that name already exists. Most of the
time, this is because of an error with VirtualBox not cleaning up
properly. To fix this, verify that no VMs with that name do exist
(by opening the VirtualBox GUI). If they don't, then look at the
folder in the error message from VirtualBox below and remove it
if there isn't any information you need in there.

VirtualBox error:

VBoxManage: error: Could not rename the directory '/Users/XXXXXXX/VirtualBox VMs/ubuntu-18.04-amd64_1619926105557_22107' to '/Users/XXXXXXX/VirtualBox VMs/load-balancer' to save the settings file (VERR_ALREADY_EXISTS)
VBoxManage: error: Details: code NS_ERROR_FAILURE (0x80004005), component SessionMachine, interface IMachine, callee nsISupports
VBoxManage: error: Context: "SaveSettings()" at line 3249 of file VBoxManageModifyVM.cpp
```

> Simple can run command with path from error
```bash
$ rm -rf /Users/XXXXXXX/VirtualBox VMs/load-balancer
```

> Better to comment below line from your vagrantfile
```bash
    config.ssh.keep_alive = true
```