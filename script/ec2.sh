#!/bin/bash 
export DEBIAN_FRONTEND=noninteractive

# Disable ssh login
echo "Still starting up" | sudo tee /run/nologin

# User Ubuntu durch knorr ersetzen
usermod -l knorr ubuntu
groupmod -n knorr ubuntu
usermod -d /home/knorr -m knorr
usermod -c "Moritz Knorr" knorr

# Init holen
cd /home/knorr/
git clone https://github.com/moritzknorr/init.git
cp init/config/bashrc.bashrc /home/knorr/.bashrc
cp init/config/vimrc.vimrc /home/knorr/.vimrc
cp init/config/gitconfig.gitconfig /home/knorr/.gitconfig
cp init/config/tmux.tmux.conf /home/knorr/.tmux.conf

# Alle Dateien in /home/knorr ownen
chown -R knorr:knorr /home/knorr

# Zeitzone einstellen:
echo 'TZ='Europe/Berlin'; export TZ' >> /home/knorr/.profile

# Instanz um 01:00 Uhr herunterfahren
crontab -l > cronjobs
echo "0 1 * * * /usr/sbin/shutdown now" >> cronjobs
crontab cronjobs
rm cronjobs

# Passwort für sudo bei User knorr nicht mehr abfragen
echo 'knorr ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Ready Datei anlegen
touch /home/knorr/ready_user

mkdir /home/knorr/.ssh
ssh-keyscan github.com > /home/knorr/.ssh/known_hosts

# Enable ssh login
rm /run/nologin

apt -yy update

# cleanup for fresh docker installation
apt -yy remove docker docker-engine docker.io containerd runc
apt -yy install $(cat init/script/software.txt)


# install docker-compose from docker
apt version does not support version 3.6
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# adduser to docker group
usermod -a -G docker knorr

# Software Ready Datei anlegen
touch /home/knorr/ready_software
