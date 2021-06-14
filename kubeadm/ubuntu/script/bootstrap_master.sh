#!/usr/bin/env bash

ufw allow 179/tcp
ufw allow 4789/tcp
ufw allow 5473/tcp
ufw allow 443/tcp
ufw allow 6443/tcp
ufw allow 2379/tcp
ufw allow 4149/tcp
ufw allow 10250/tcp
ufw allow 10255/tcp
ufw allow 10256/tcp
ufw allow 9099/tcp
ufw allow 10251/tcp
ufw allow 10252/tcp
ufw allow 8080/tcp
ufw allow 2379:2380/tcp
sudo ufw allow 2380/tcp
sudo ufw reload
