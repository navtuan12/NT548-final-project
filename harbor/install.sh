#!/bin/bash
sudo apt-get update
sudo apt-get install ca-certificates certbot curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

wget https://github.com/goharbor/harbor/releases/download/v2.11.2/harbor-online-installer-v2.11.2.tgz
tar -xvzf harbor-online-installer-v2.11.2.tgz

export EMAIL=anhtuan.mmt@gmail.com
export DOMAIN=reg.devnoneknow.online
export PASSWORD=nt548@harbor

cd harbor/
cp harbor.yml.tmpl harbor.yml

sudo certbot certonly --agree-tos --email $EMAIL -d $DOMAIN --non-interactive --standalone

sed -i "s|hostname: reg.mydomain.com|hostname: $DOMAIN|" harbor.yml
sed -i "s|harbor_admin_password: .*|harbor_admin_password: $PASSWORD|" harbor.yml
sed -i "s|certificate: /your/certificate/path|certificate: /etc/letsencrypt/live/$DOMAIN/fullchain.pem|" harbor.yml
sed -i "s|private_key: /your/private/key/path|private_key: /etc/letsencrypt/live/$DOMAIN/privkey.pem|" harbor.yml

sudo hostnamectl set-hostname $DOMAIN
sudo ./install.sh
