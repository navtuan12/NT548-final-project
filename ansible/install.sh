#!/bin/bash
sudo apt update
sudo apt install python3-pip python3-venv -y

python3 -m venv --system-site-packages ansible

source ansible/bin/activate

pip install ansible -y

ansible-playbook -i inventory.ini playbook.yml