#!/bin/bash
sudo apt update
sudo apt install socat conntrack -y

sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^Include/#Include/' /etc/ssh/sshd_config

sudo systemctl restart ssh
