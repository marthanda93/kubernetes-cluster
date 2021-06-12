config.vm.provision "vm-setup", type: "shell" do |vms|
    vms.path = "script/bootstrap.sh"
    vms.args   = ["#{k8s['user']}"]
end