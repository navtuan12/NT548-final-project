#!/bin/bash
sudo apt update
sudo apt install python3-pip python3-venv sshpass -y

python3 -m venv --system-site-packages ansible

source ansible/bin/activate

pip install ansible -y
sshpass -p '123' /home/ubuntu/config.yml ubuntu@10.0.1.10:/home/ubuntu/
ansible-playbook -i inventory.ini playbook.yml