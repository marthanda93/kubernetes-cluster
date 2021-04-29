#!/usr/bin/env bash

echo "ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y" | su - ${1}

ufw enable <<<y
ufw allow 22
