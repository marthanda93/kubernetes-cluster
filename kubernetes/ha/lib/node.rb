config.vm.define "#{k8s['cluster']['node']}-#{i}" do |subconfig|
    subconfig.vm.box = k8s['image']

    subconfig.vm.hostname = "#{k8s['cluster']['node']}-#{i}"
    subconfig.vm.network :private_network, ip: "#{k8s['ip_part']}.#{i + k8s['resources']['node']['ip_prefix']}"

    # Hostfile :: Master node
    subconfig.vm.provision "Load Balancer hostfile update", type: "shell" do |lb|
        lb.inline = <<-SHELL
            echo -e "127.0.0.1\t$1" | tee -a /etc/hosts
        SHELL
        lb.args = ["#{k8s['cluster']['node']}"]
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
        vb.memory = k8s['resources']['node']['memory']
        vb.cpus = k8s['resources']['node']['cpus']
        vb.name = "#{k8s['cluster']['node']}-#{i}"
        vb.gui = false
    end

    subconfig.vm.provision "firewall update", type: "shell" do |s|
        s.inline = <<-SHELL
            ufw allow 10250/tcp
            ufw allow 10251/tcp
            ufw allow 10255/tcp
            ufw allow 30000:32767/tcp
            ufw reload
        SHELL
    end

    subconfig.vm.provision "Restart VM", type: "shell" do |reboot|
        reboot.privileged = true
        reboot.inline = <<-SHELL
            echo "----------------------------------|| Reboot to load all config"
        SHELL
        reboot.reboot = true
    end
end