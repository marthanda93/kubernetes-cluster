config.vm.define "#{k8s['cluster']['master']}" do |subconfig|
    subconfig.vm.post_up_message = $msg
    subconfig.vm.box = k8s['image']

    subconfig.vm.hostname = "#{k8s['cluster']['master']}"
    subconfig.vm.network :private_network, ip: "#{k8s['ip_part']}.10"

    # Hostfile :: Master node
    subconfig.vm.provision "master-hostfile", type: "shell" do |mhf|
        mhf.inline = <<-SHELL
            echo -e "127.0.0.1\t$2" | tee -a /etc/hosts; echo -e "$1\t$2" | tee -a /etc/hosts
        SHELL
        mhf.args = ["#{k8s['ip_part']}.10", "#{k8s['cluster']['master']}"]
    end
    # Hostfile :: Worker node
    subconfig.vm.provision "Update hostfile and authorized_keys", type: "shell" do |whu|
        whu.inline = <<-SHELL
            for i in $(eval echo {1..$2}); do 
                echo -e "${3}.$((10 + $i))\t#{k8s['cluster']['node']}-${i}" | tee -a /etc/hosts
            done
        SHELL
        whu.args   = ["#{k8s['user']}", "#{k8s['resources']['node']['count']}", "#{k8s['ip_part']}"]
    end

    subconfig.vm.provider "virtualbox" do |vb|
        vb.memory = k8s['resources']['master']['memory']
        vb.cpus = k8s['resources']['master']['cpus']
    end

    subconfig.vm.provision "Restart VM", type: "shell" do |reboot|
        reboot.privileged = true
        reboot.inline = <<-SHELL
            echo "----------------------------------|| Reboot to load all config"
        SHELL
        reboot.reboot = true
    end

    subconfig.vm.provision "#{k8s['cluster']['master']}-setup", type: "shell" do |mns|
        mns.path = "script/bootstrap_master.sh"
        mns.args   = ["#{k8s['user']}", "#{k8s['ip_part']}", "10"]
    end

    subconfig.trigger.after :up do |trigger_local|
        trigger_local.run = {inline: "/bin/bash -c 'vagrant ssh --no-tty -c \"cat /etc/kubernetes/admin.conf\" #{k8s['cluster']['master']} > admin.conf && rm -f \${HOME}/.kube/config 2>/dev/null; mkdir -p \${HOME}/.kube; cp -i admin.conf \${HOME}/.kube/config; rm -f admin.conf'"}
    end
end