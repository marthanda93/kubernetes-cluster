config.trigger.after :up do |trigger|
    trigger.only_on = "#{k8s['cluster']['node']}-#{k8s['resources']['node']['count']}"
    trigger.info = msg

    trigger.ruby do |env,machine|
        mpub, stdeerr, status = Open3.capture3("vagrant ssh --no-tty -c 'cat /home/" + k8s['user'] + "/.ssh/id_rsa.pub' " + k8s['cluster']['master'])
        kubeadm_join, stdeerr, status = Open3.capture3("vagrant ssh --no-tty -c \"sudo kubeadm init --apiserver-advertise-address=#{k8s['ip_part']}.10 --apiserver-cert-extra-sans=#{k8s['ip_part']}.10  --node-name master-node --pod-network-cidr=#{k8s['ip_part']}.0/16 --token-ttl 0 | grep -A2 'kubeadm join' | xargs -L 2 | paste -sd ''\" #{k8s['cluster']['master']}")

        system("vagrant ssh --no-tty -c 'mkdir -p $HOME/.kube' #{k8s['cluster']['master']}")
        system("vagrant ssh --no-tty -c 'sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config' #{k8s['cluster']['master']}")
        system("vagrant ssh --no-tty -c 'sudo chown $(id -u):$(id -g) $HOME/.kube/config' #{k8s['cluster']['master']}")
        system("vagrant ssh --no-tty -c 'echo \"export KUBECONFIG=/etc/kubernetes/admin.conf\" >> $HOME/.bash_profile' #{k8s['cluster']['master']}")
        system("vagrant ssh --no-tty -c 'sudo chown #{k8s['user']} /etc/kubernetes/admin.conf' #{k8s['cluster']['master']}")
        system('vagrant ssh --no-tty -c \'echo "export KUBEADM_JOIN=\"'+ kubeadm_join.strip + '\"" >> /home/vagrant/.bash_profile\' master-node')
        system("vagrant ssh --no-tty -c 'kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml' #{k8s['cluster']['master']}")

        1.step(k8s['resources']['node']['count']) do |m|
            wpub, stdeerr, status = Open3.capture3("vagrant ssh --no-tty -c 'cat /home/" + k8s['user'] + "/.ssh/id_rsa.pub' " + k8s['cluster']['node'] + "-#{m}")
            system("vagrant ssh --no-tty -c 'echo \"#{wpub}\" >> /home/" + k8s['user'] + "/.ssh/authorized_keys' " + k8s['cluster']['master'])
            system("vagrant ssh --no-tty -c 'echo \"#{mpub}\" >> /home/" + k8s['user'] + "/.ssh/authorized_keys' " + k8s['cluster']['node'] + "-#{m}")

            system("vagrant ssh --no-tty -c 'sudo #{kubeadm_join}' " + k8s['cluster']['node'] + "-#{m}")
            system("vagrant ssh --no-tty -c 'mkdir -p /home/#{k8s['user']}/.kube' " + k8s['cluster']['node'] + "-#{m}")
            system("vagrant ssh --no-tty -c 'scp -o StrictHostKeyChecking=no #{k8s['user']}@#{k8s['cluster']['master']}:/etc/kubernetes/admin.conf /home/#{k8s['user']}/.kube/' " + k8s['cluster']['node'] + "-#{m}")
            system("vagrant ssh --no-tty -c 'echo \"export KUBECONFIG=\${HOME}/.kube/admin.conf\" >> /home/#{k8s['user']}/.bash_profile' #{k8s['cluster']['node']}" + "-#{m}")
            system("vagrant ssh --no-tty -c 'kubectl label nodes #{k8s['cluster']['node']}-#{m} kubernetes.io/role=#{k8s['cluster']['node']}-#{m}' " + k8s['cluster']['node'] + "-#{m}")
        end

        system("vagrant ssh --no-tty -c 'cat /etc/kubernetes/admin.conf' #{k8s['cluster']['master']} > admin.conf && rm -f \${HOME}/.kube/config 2>/dev/null; mkdir -p \${HOME}/.kube; cp -i admin.conf \${HOME}/.kube/config; rm -f admin.conf")
    end
end
