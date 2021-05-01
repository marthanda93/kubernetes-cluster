config.vm.define "#{k8s['cluster']['master']}-#{i}" do |subconfig|
    # subconfig.vm.post_up_message = $msg
    subconfig.vm.box = k8s['image']
    subconfig.vm.box_check_update = false

    subconfig.vm.hostname = "#{k8s['cluster']['master']}-#{i}"
    subconfig.vm.network :private_network, ip: "#{k8s['ip_part']}.#{i + k8s['resources']['master']['ip_prefix']}"

    # Hostfile :: Master node
    subconfig.vm.provision "Load Balancer hostfile update", type: "shell" do |lb|
        lb.inline = <<-SHELL
            echo -e "127.0.0.1\t$1" | tee -a /etc/hosts; echo -e "$2\t$3" | tee -a /etc/hosts
        SHELL
        lb.args = ["#{k8s['cluster']['master']}-#{i}", "#{k8s['ip_part']}.#{k8s['resources']['ha']['ip_prefix']}", "#{k8s['cluster']['ha']}"]
    end
    subconfig.vm.provision "Master and Worker node hostfile update", type: "shell" do |cluster|
        cluster.inline = <<-SHELL
            # master
            for i in $(eval echo {1..#{k8s['resources']['master']['count']}}); do
                echo -e "${1}.$((#{k8s['resources']['master']['ip_prefix']} + $i))\t#{k8s['cluster']['master']}-${i}" | tee -a /etc/hosts
            done

            # worker
            for i in $(eval echo {1..#{k8s['resources']['node']['count']}}); do
                echo -e "${1}.$((#{k8s['resources']['node']['ip_prefix']} + $i))\t#{k8s['cluster']['node']}-${i}" | tee -a /etc/hosts
            done
        SHELL
        cluster.args = ["#{k8s['ip_part']}"]
    end

    subconfig.vm.provider "virtualbox" do |vb|
        vb.name = "#{k8s['cluster']['master']}-#{i}"
        vb.memory = k8s['resources']['master']['memory']
        vb.cpus = k8s['resources']['master']['cpus']
        vb.gui = false
    end

    subconfig.vm.provision "vm-setup", type: "shell" do |vms|
        vms.path = "script/bootstrap.sh"
        vms.args   = ["#{k8s['user']}"]
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
end
