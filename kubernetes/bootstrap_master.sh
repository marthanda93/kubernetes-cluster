#!/usr/bin/env bash

sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
yum update -y
yum install -y git wget telnet vim net-tools zip unzip wget curl -y

yum clean all
# yum makecache fast

