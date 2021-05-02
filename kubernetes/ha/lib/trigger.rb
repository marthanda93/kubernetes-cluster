config.trigger.after :up do |trigger|
    trigger.only_on = "#{k8s['cluster']['node']}-#{k8s['resources']['node']['count']}"
    trigger.info = msg

    trigger.ruby do |env,machine|
        lbpub, stdeerr, status = Open3.capture3("vagrant ssh --no-tty -c 'cat /home/" + k8s['user'] + "/.ssh/id_rsa.pub' " + k8s['cluster']['ha'])

        1.step(k8s['resources']['master']['count']) do |m|
            mpub, stdeerr, status = Open3.capture3("vagrant ssh --no-tty -c 'cat /home/" + k8s['user'] + "/.ssh/id_rsa.pub' " + k8s['cluster']['master'] + "-#{m}")
            system("vagrant ssh --no-tty -c 'echo \"#{lbpub}\" >> /home/" + k8s['user'] + "/.ssh/authorized_keys' " + k8s['cluster']['master'] + "-#{m}")
            system("vagrant ssh --no-tty -c 'echo \"#{mpub}\" >> /home/" + k8s['user'] + "/.ssh/authorized_keys' " + k8s['cluster']['ha'])

            1.step(k8s['resources']['master']['count']) do |n|
                next if m == n
                system("vagrant ssh --no-tty -c 'echo \"#{mpub}\" >> /home/" + k8s['user'] + "/.ssh/authorized_keys' " + k8s['cluster']['master'] + "-#{n}")
            end

            1.step(k8s['resources']['node']['count']) do |e|
                system("vagrant ssh --no-tty -c 'echo \"#{mpub}\" >> /home/" + k8s['user'] + "/.ssh/authorized_keys' " + k8s['cluster']['node'] + "-#{e}")
            end

            # Push all required configs/certificates to master node
            system("vagrant ssh --no-tty -c 'scp -o StrictHostKeyChecking=no /opt/certificates/{encryption-config.yaml,kube-controller-manager.kubeconfig,kube-scheduler.kubeconfig,admin.kubeconfig,ca.pem,ca-key.pem,kubernetes-key.pem,kubernetes.pem,service-account-key.pem,service-account.pem} " + k8s['cluster']['master'] + "-#{m}" + ":~/certificates/' " + k8s['cluster']['ha'])
            # Start etcd on all controller
            system("vagrant ssh --no-tty -c 'sudo cp /home/vagrant/certificates/{ca.pem,kubernetes-key.pem,kubernetes.pem} /etc/etcd/; sudo cp /home/vagrant/certificates/{ca.pem,ca-key.pem,kubernetes-key.pem,kubernetes.pem,service-account-key.pem,service-account.pem,encryption-config.yaml} /var/lib/kubernetes/; sudo cp /home/vagrant/certificates/{kube-controller-manager.kubeconfig,kube-scheduler.kubeconfig} /var/lib/kubernetes/; sudo systemctl enable --now etcd; sudo systemctl enable --now kube-apiserver; sudo systemctl enable --now kube-controller-manager; sudo systemctl enable --now kube-scheduler; sudo systemctl enable --now nginx; mkdir -p /home/" + k8s['user'] + "/.kube; cp -i /home/" + k8s['user'] + "/certificates/admin.kubeconfig /home/" + k8s['user'] + "/.kube/config' " + k8s['cluster']['master'] + "-#{m}")
        end

        1.step(k8s['resources']['node']['count']) do |m|
            wpub, stdeerr, status = Open3.capture3("vagrant ssh --no-tty -c 'cat /home/" + k8s['user'] + "/.ssh/id_rsa.pub' " + k8s['cluster']['node'] + "-#{m}")
            system("vagrant ssh --no-tty -c 'echo \"#{lbpub}\" >> /home/" + k8s['user'] + "/.ssh/authorized_keys' " + k8s['cluster']['node'] + "-#{m}")
            system("vagrant ssh --no-tty -c 'echo \"#{wpub}\" >> /home/" + k8s['user'] + "/.ssh/authorized_keys' " + k8s['cluster']['ha'])

            1.step(k8s['resources']['node']['count']) do |n|
                next if m == n
                system("vagrant ssh --no-tty -c 'echo \"#{wpub}\" >> /home/" + k8s['user'] + "/.ssh/authorized_keys' " + k8s['cluster']['node'] + "-#{n}")
            end

            1.step(k8s['resources']['master']['count']) do |e|
                system("vagrant ssh --no-tty -c 'echo \"#{wpub}\" >> /home/" + k8s['user'] + "/.ssh/authorized_keys' " + k8s['cluster']['master'] + "-#{e}")
            end

            # Push all required configs/certificates to worker node
            system("vagrant ssh --no-tty -c 'scp -o StrictHostKeyChecking=no /opt/certificates/{" + k8s['cluster']['node'] + "-#{m}.kubeconfig" + ",kube-proxy.kubeconfig,ca.pem,admin.kubeconfig," + k8s['cluster']['node'] + "-#{m}.pem," + k8s['cluster']['node'] + "-#{m}-key.pem} " + k8s['cluster']['node'] + "-#{m}" + ":~/certificates/' " + k8s['cluster']['ha'])
            # Bootstrapping the Kubernetes Worker Nodes
            system("vagrant ssh --no-tty -c 'sudo cp /home/vagrant/certificates/{" + k8s['cluster']['node'] + "-#{m}-key.pem," + k8s['cluster']['node'] + "-#{m}.pem} /var/lib/kubelet/; sudo cp /home/vagrant/certificates/" + k8s['cluster']['node'] + "-#{m}.kubeconfig /var/lib/kubelet/kubeconfig; sudo cp /home/vagrant/certificates/ca.pem /var/lib/kubernetes/; sudo cp /home/vagrant/certificates/kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig; sudo systemctl enable --now kubelet; sudo systemctl enable --now kube-proxy; sudo systemctl enable --now containerd; mkdir -p /home/" + k8s['user'] + "/.kube; cp -i /home/" + k8s['user'] + "/certificates/admin.kubeconfig /home/" + k8s['user'] + "/.kube/config' " + k8s['cluster']['node'] + "-#{m}")
        end

        system("vagrant ssh --no-tty -c 'kubectl apply --kubeconfig /home/vagrant/certificates/admin.kubeconfig -f /home/vagrant/certificates/cluster_role.yaml; kubectl apply --kubeconfig /home/vagrant/certificates/admin.kubeconfig -f /home/vagrant/certificates/cluster_role_binding.yaml' " + k8s['cluster']['master'] + "-1")
        
        # Configuring kubectl for Remote Access
        system("mkdir -p ${HOME}/.kube")
        system("vagrant ssh --no-tty -c 'cat /opt/certificates/ca.pem' " + k8s['cluster']['ha'] + " > ${HOME}/.kube/ca.pem")
        system("vagrant ssh --no-tty -c 'cat /opt/certificates/admin.pem' " + k8s['cluster']['ha'] + " > ${HOME}/.kube/admin.pem")
        system("vagrant ssh --no-tty -c 'cat /opt/certificates/admin-key.pem' " + k8s['cluster']['ha'] + " > ${HOME}/.kube/admin-key.pem")
        system("kubectl config set-cluster kubernetes-the-hard-way --certificate-authority=${HOME}/.kube/ca.pem --embed-certs=true --server=https://#{k8s['ip_part']}.#{k8s['resources']['ha']['ip_prefix']}:6443 && kubectl config set-credentials admin --client-certificate=${HOME}/.kube/admin.pem --client-key=${HOME}/.kube/admin-key.pem && kubectl config set-context kubernetes-the-hard-way --cluster=kubernetes-the-hard-way --user=admin && kubectl config use-context kubernetes-the-hard-way")

        # Deploying the DNS Cluster Add-on
        system("kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.8.yaml")
    end
end
