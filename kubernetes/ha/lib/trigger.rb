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
            system("vagrant ssh --no-tty -c 'scp -o StrictHostKeyChecking=no /opt/certificates/encryption-config.yaml /opt/certificates/kube-controller-manager.kubeconfig /opt/certificates/kube-scheduler.kubeconfig /opt/certificates/admin.kubeconfig /opt/certificates/ca.pem /opt/certificates/ca-key.pem /opt/certificates/kubernetes-key.pem /opt/certificates/kubernetes.pem /opt/certificates/service-account-key.pem /opt/certificates/service-account.pem " + k8s['cluster']['master'] + "-#{m}" + ":~/certificates/' " + k8s['cluster']['ha'])
            # Start etcd on all controller
            system("vagrant ssh --no-tty -c 'cp /home/vagrant/certificates/ca.pem /home/vagrant/certificates/kubernetes-key.pem /home/vagrant/certificates/kubernetes.pem /etc/etcd/; systemctl enable --now etcd' " + k8s['cluster']['master'] + "-#{m}")
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
            system("vagrant ssh --no-tty -c 'scp -o StrictHostKeyChecking=no /opt/certificates/" + k8s['cluster']['node'] + "-#{m}.kubeconfig" + " /opt/certificates/kube-proxy.kubeconfig /opt/certificates/ca.pem /opt/certificates/" + k8s['cluster']['node'] + "-#{m}.pem /opt/certificates/" + k8s['cluster']['node'] + "-#{m}-key.pem " + k8s['cluster']['node'] + "-#{m}" + ":~/certificates/' " + k8s['cluster']['ha'])
        end
    end
end
