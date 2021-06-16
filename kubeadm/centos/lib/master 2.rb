config.vm.define "#{k8s['cluster']['master']}" do |subconfig|
    subconfig.vm.box = k8s['image']
    subconfig.vm.box_check_update = false

    subconfig.vm.hostname = "#{k8s['cluster']['master']}"
    subconfig.vm.network :private_network, ip: "#{k8s['ip_part']}.10"

    subconfig.vm.provider "virtualbox" do |vb|
        vb.memory = k8s['resources']['master']['memory']
        vb.cpus = k8s['resources']['master']['cpus']
    end

    subconfig.vm.provision "#{k8s['cluster']['master']}-initial-setup", type: "shell" do |ins|
        ins.path = "script/bootstrap.sh"
        ins.args   = ["#{k8s['user']}"]
    end

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

    subconfig.vm.provision "Enable Firewall", type: "shell" do |enable_firewall|
        enable_firewall.inline = <<-SHELL
            firewall-cmd --permanent --add-port=6443/tcp
            firewall-cmd --permanent --add-port=2379-2380/tcp
            firewall-cmd --permanent --add-port=10250/tcp
            firewall-cmd --permanent --add-port=10251/tcp
            firewall-cmd --permanent --add-port=10252/tcp
            firewall-cmd --permanent --add-port=8080/tcp
            firewall-cmd --permanent --add-port=179/tcp
            firewall-cmd --permanent --add-port=5473/tcp
            firewall-cmd --permanent --add-port=4789/udp
            firewall-cmd --permanent --add-port=443/tcp
            firewall-cmd --permanent --add-port=2379/tcp
            firewall-cmd --reload
        SHELL
    end

    subconfig.vm.provision "Reboot to load all config", type:"shell", inline: "shutdown -r now"
end
