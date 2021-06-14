config.vm.define "#{k8s['cluster']['node']}-#{i}" do |subconfig|
    subconfig.vm.box = k8s['image']

    subconfig.vm.hostname = "#{k8s['cluster']['node']}-#{i}"
    subconfig.vm.network :private_network, ip: "#{k8s['ip_part']}.#{i + 10}"

    # Hostfile :: Master node
    subconfig.vm.provision "master-hostfile", type: "shell" do |s|
        s.inline = <<-SHELL
            echo -e "$1\t$2" | tee -a /etc/hosts
            ufw allow 10250/tcp
            ufw allow 10251/tcp
            ufw allow 10255/tcp
            ufw allow 30000:32767/tcp
            ufw reload
        SHELL
        s.args = ["#{k8s['ip_part']}.10", "#{k8s['cluster']['master']}"]
    end
    # Hostfile :: Worker node
    (1..k8s['resources']['node']['count']).each do |j|
        if i != j
            subconfig.vm.provision "other-worker-hostfile", type: "shell" do |supdate|
                supdate.inline = <<-SHELL
                    echo -e "$1\t$2" | tee -a /etc/hosts
                SHELL
                supdate.args = ["#{k8s['ip_part']}.#{10 + j}", "#{k8s['cluster']['node']}-#{j}", "#{k8s['user']}", "#{i}"]
            end
        else
            subconfig.vm.provision "self-worker-hostfile", type: "shell" do |supdate|
                supdate.inline = <<-SHELL
                    echo -e "127.0.0.1\t$2" | tee -a /etc/hosts; echo -e "$1\t$2" | tee -a /etc/hosts
                SHELL
                supdate.args = ["#{k8s['ip_part']}.#{10 + j}", "#{k8s['cluster']['node']}-#{j}", "#{k8s['user']}", "#{i}"]
            end
        end
    end

    subconfig.vm.provider "virtualbox" do |vb|
        vb.memory = k8s['resources']['node']['memory']
        vb.cpus = k8s['resources']['node']['cpus']
    end

    subconfig.vm.provision "#{k8s['cluster']['master']}-initial-setup", type: "shell" do |ins|
        ins.path = "script/bootstrap.sh"
        ins.args   = ["#{k8s['user']}"]
    end

    subconfig.vm.provision "Reboot to load all config", type:"shell", inline: "shutdown -r now"
end