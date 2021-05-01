config.vm.define "#{k8s['cluster']['ha']}" do |subconfig|
    subconfig.vm.post_up_message = $msg
    subconfig.vm.box = k8s['image']
    subconfig.vm.box_check_update = false

    subconfig.vm.hostname = "#{k8s['cluster']['ha']}"
    subconfig.vm.network :private_network, ip: "#{k8s['ip_part']}.10"

    # Hostfile :: Master node
    subconfig.vm.provision "Load Balancer hostfile update", type: "shell" do |lb|
        lb.inline = <<-SHELL
            echo -e "127.0.0.1\t$2" | tee -a /etc/hosts; echo -e "$1\t$2" | tee -a /etc/hosts
        SHELL
        lb.args = ["#{k8s['ip_part']}.10", "#{k8s['cluster']['ha']}"]
    end
    subconfig.vm.provision "Master and Worker node hostfile update", type: "shell" do |cluster|
        cluster.inline = <<-SHELL
            # master
            for i in $(eval echo {1..#{k8s['resources']['master']['count']}}); do
                echo -e "${1}.$((10 + $i))\t#{k8s['cluster']['master']}-${i}" | tee -a /etc/hosts
            done
            # worker
            for i in $(eval echo {1..#{k8s['resources']['node']['count']}}); do
                echo -e "${1}.$((20 + $i))\t#{k8s['cluster']['node']}-${i}" | tee -a /etc/hosts
            done
        SHELL
        cluster.args = ["#{k8s['ip_part']}"]
    end

    subconfig.vm.provider "virtualbox" do |vb|
        vb.memory = k8s['resources']['ha']['memory']
        vb.cpus = k8s['resources']['ha']['cpus']
        vb.name = "#{k8s['cluster']['ha']}"
        vb.gui = false
    end

    subconfig.vm.provision "#{k8s['cluster']['ha']}-setup", type: "shell" do |lb|
        lb.path = "script/bootstrap_ha.sh"
        lb.args   = ["#{k8s['user']}", "#{k8s['ip_part']}", "#{k8s['cluster']['master']}", "#{k8s['resources']['master']['count']}"]
    end

    subconfig.vm.provision "certificates provisioning", type: "shell" do |lb_cert|
        lb_cert.path = "script/provisioning.sh"
        lb_cert.args   = ["#{k8s['ip_part']}", "#{k8s['resources']['master']['ip_prefix']}", "#{k8s['resources']['node']['ip_prefix']}", "#{k8s['resources']['ha']['ip_prefix']}", "#{k8s['cluster']['master']}", "#{k8s['cluster']['node']}", "#{k8s['resources']['master']['count']}", "#{k8s['resources']['node']['count']}"]
    end

    subconfig.vm.provision "Generating Kubernetes Configuration", type: "shell" do |lb_config|
        lb_config.path = "script/kube_config.sh"
        lb_config.args   = ["#{k8s['ip_part']}", "#{k8s['resources']['master']['ip_prefix']}", "#{k8s['resources']['node']['ip_prefix']}", "#{k8s['resources']['ha']['ip_prefix']}", "#{k8s['cluster']['master']}", "#{k8s['cluster']['node']}", "#{k8s['resources']['master']['count']}", "#{k8s['resources']['node']['count']}"]
    end

    subconfig.vm.provision "Restart VM", type: "shell" do |reboot|
        reboot.privileged = true
        reboot.inline = <<-SHELL
            echo "----------------------------------|| Reboot to load all config"
        SHELL
        reboot.reboot = true
    end
end
