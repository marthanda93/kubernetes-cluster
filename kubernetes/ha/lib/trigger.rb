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

            system("vagrant ssh --no-tty -c 'scp -o StrictHostKeyChecking=no /opt/certificates/ca.pem /opt/certificates/ca-key.pem /opt/certificates/kubernetes-key.pem /opt/certificates/kubernetes.pem /opt/certificates/service-account-key.pem /opt/certificates/service-account.pem " + k8s['cluster']['master'] + "-#{m}" + ":~/' " + k8s['cluster']['ha'])
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

            system("vagrant ssh --no-tty -c 'scp -o StrictHostKeyChecking=no /opt/certificates/ca.pem /opt/certificates/" + k8s['cluster']['node'] + "-#{m}.pem /opt/certificates/" + k8s['cluster']['node'] + "-#{m}-key.pem " + k8s['cluster']['node'] + "-#{m}" + ":~/' " + k8s['cluster']['ha'])
        end
    end
end
