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

    subconfig.trigger.after :up do |trigger_local|
        trigger_local.run = {inline: "/bin/bash -c 'wpub_key=$(vagrant ssh --no-tty -c \"cat /home/#{k8s['user']}/.ssh/id_rsa.pub\" #{k8s['cluster']['node']}-#{i}) && vagrant ssh --no-tty -c \"echo \${wpub_key} >> /home/#{k8s['user']}/.ssh/authorized_keys\" #{k8s['cluster']['master']}; mpub_key=$(vagrant ssh --no-tty -c \"cat /home/#{k8s['user']}/.ssh/id_rsa.pub\" #{k8s['cluster']['master']}) && vagrant ssh --no-tty -c \"echo \${mpub_key} >> /home/#{k8s['user']}/.ssh/authorized_keys\" #{k8s['cluster']['node']}-#{i}'"}
    end

    subconfig.trigger.after :up do |trigger_remote|
        trigger_remote.run_remote = {inline: <<-SHELL
                kube_join=\$(echo "ssh #{k8s['user']}@#{k8s['cluster']['master']} -o StrictHostKeyChecking=no '( cat /home/#{k8s['user']}/.bash_profile | grep KUBEADM_JOIN)'" | su - #{k8s['user']})
                kube_join=\$(echo ${kube_join} | awk -F'"' '{print \$2}')
                echo "sudo $kube_join" | su - #{k8s['user']}
                echo "scp -o StrictHostKeyChecking=no #{k8s['user']}@#{k8s['cluster']['master']}:/etc/kubernetes/admin.conf /home/#{k8s['user']}/" | su - #{k8s['user']}
                echo "mkdir -p /home/#{k8s['user']}/.kube" | su - #{k8s['user']}
                echo "cp -i /home/#{k8s['user']}/admin.conf /home/#{k8s['user']}/.kube/config" | su - #{k8s['user']}
                echo "sudo chown #{k8s['user']}:#{k8s['user']} -R /home/#{k8s['user']}/.kube" | su - #{k8s['user']}
                echo "kubectl label nodes #{k8s['cluster']['node']}-#{i} kubernetes.io/role=#{k8s['cluster']['node']}-#{i}" | su - #{k8s['user']}
            SHELL
        }
    end

    subconfig.vm.provision "Restart VM", type: "shell" do |reboot|
        reboot.privileged = true
        reboot.inline = <<-SHELL
            echo "----------------------------------|| Reboot to load all config"
        SHELL
        reboot.reboot = true
    end
end