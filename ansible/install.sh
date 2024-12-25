#!/bin/bash
sudo apt update
sudo apt install python3-pip python3-venv sshpass -y
cd /home/ubuntu
python3 -m venv --system-site-packages ansible

source ansible/bin/activate

sudo apt install ansible-core -y
export ANSIBLE_HOST_KEY_CHECKING=False

ansible-playbook -i inventory.ini 00-init-playbook.yml
ansible-playbook -i inventory.ini 01-join-node-playbook.yml