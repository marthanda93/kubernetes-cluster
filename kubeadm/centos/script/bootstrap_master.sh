#!/usr/bin/env bash

firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10252/tcp
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --permanent --add-port=179/tcp
firewall-cmd --permanent --add-port=5473/tcp
firewall-cmd --permanent --add-port=4789/udp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=2379/tcp
firewall-cmd --reload
