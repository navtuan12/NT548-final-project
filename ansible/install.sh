#!/bin/bash
sudo apt update
sudo apt install python3-pip python3-venv sshpass -y
cd /home/ubuntu
python3 -m venv --system-site-packages ansible

source ansible/bin/activate

sudo apt install ansible-core -y
export ANSIBLE_HOST_KEY_CHECKING=False

sshpass -p "123" scp config.yml ubuntu@10.0.1.10:/home/ubuntu/
ansible-playbook -i inventory.ini playbook.yml